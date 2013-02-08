//
//  Transit.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "Transit.h"
#import "SBJson.h"

@implementation NSString(TransRegExp)

-(NSString*)stringByReplacingMatchesOf:(NSRegularExpression*)regex withTransformation:(NSString*(^)(NSString*element)) block {

    NSMutableString* mutableString = [self mutableCopy];
    NSInteger offset = 0;

    for (NSTextCheckingResult* result in [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)]) {
        
        NSRange resultRange = [result range];
        resultRange.location += offset;
        
        NSString* match = [regex replacementStringForResult:result
                                                   inString:mutableString
                                                     offset:offset
                                                   template:@"$0"];

        NSString* replacement = block(match);
        
        // make the replacement
        [mutableString replaceCharactersInRange:resultRange withString:replacement];
        
        // update the offset based on the replacement
        offset += ([replacement length] - resultRange.length);
    }
    return mutableString;
}

@end

@implementation TransitProxy

-(id)eval:(NSString*)jsCode {
    return [self eval:jsCode thisArg:nil arguments:@[]];
}

-(id)eval:(NSString*)jsCode arguments:(NSArray*)arguments {
    return [self eval:jsCode thisArg:nil arguments:arguments];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arguments:(NSArray*)arguments {
    @throw @"must be implemented by subclass";
}

+(NSString*)jsRepresentation:(id)object {
    SBJsonWriter* writer = [SBJsonWriter new];
    NSString* json = [writer stringWithObject: @[object]];
    if(json == nil)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"cannot be represented as JSON: %@", object] userInfo:nil];

    return [json substringWithRange:NSMakeRange(1, json.length-2)];
}

+(NSString*)jsExpressionFromCode:(NSString*)jsCode arguments:(NSArray*)arguments {
    NSError* error;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"@"
                                  options:0
                                  error:&error];
    
    NSMutableArray* mutableArguments = [arguments mutableCopy];
    jsCode = [jsCode stringByReplacingMatchesOf:regex withTransformation:^(NSString* match){
        if(mutableArguments.count <=0)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"too few arguments" userInfo:nil];
        
        NSString* result =  [NSString stringWithFormat:@"%@", [self jsRepresentation:mutableArguments[0]]];
        
        [mutableArguments removeObjectAtIndex:0];
        return result;
    }];
    
    if(mutableArguments.count >0)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"too many arguments" userInfo:nil];
    
    return jsCode;
}

@end

@implementation TransitContext
@end

@implementation TransitUIWebViewContext

+(id)contextWithUIWebView:(UIWebView*)webView {
    return [[self alloc] initWithUIWebView: webView];
}

-(id)initWithUIWebView:(UIWebView*)webView {
    self = [self init];
    if(self) {
        _webView = webView;
    }
    return self;
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg arguments:(NSArray *)arguments {
    SBJsonParser *parser = [SBJsonParser new];
    NSString* jsExpression = [self.class jsExpressionFromCode:jsCode arguments:arguments];
    NSString* jsThisArg = thisArg ? [TransitProxy jsRepresentation:thisArg] : @"null";
    NSString* jsApplyExpression = [NSString stringWithFormat:@"function(){return %@;}.call(%@)", jsExpression, jsThisArg];
    NSString* js = [NSString stringWithFormat: @"JSON.stringify({v: %@})", jsApplyExpression];
    NSString* jsResult = [_webView stringByEvaluatingJavaScriptFromString: js];
    return [parser objectWithString:jsResult][@"v"];
}

@end

@implementation TransitFunction

-(id)initWithRootContext:(TransitContext*)rootContext {
    self = [self init];
    if(self) {
        _rootContext = rootContext;
    }
    return self;
}

-(id)call {
    return [self callWithThisArg:nil arguments:@[]];
}

-(id)callWithArguments:(NSArray*)arguments {
    return [self callWithThisArg:nil arguments:arguments];
}

-(id)callWithThisArg:(TransitProxy*)thisArg arguments:(NSArray*)arguments {
    @throw @"must be implemented by subclass";
}

@end

@implementation TransitNativeFunction

-(id)initWithRootContext:(TransitContext *)rootContext nativeId:(NSString*)nativeId block:(TransitFunctionBlock)block {
    self = [self initWithRootContext:rootContext];
    if(self) {
        _nativeId = nativeId;
        _block = block;
    }
    return self;
}

-(id)callWithThisArg:(TransitProxy*)thisArg arguments:(NSArray*)arguments {
    if(!_block)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"block is nil" userInfo:nil];
    
    return _block(thisArg, arguments);
}

@end
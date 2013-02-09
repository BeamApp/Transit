//
//  Transit.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "Transit.h"
#import "Transit+Private.h"
#import "SBJson.h"

@implementation TransitJSDirectExpression

-(id)initWithExpression:(NSString*)expression {
    self = [self init];
    if(self) {
        _expression = expression;
    }
    return self;
}

-(NSString*)jsRepresentation{
    return _expression;
}

+(id)expression:(NSString*)expression {
    return [[self alloc] initWithExpression:expression];
}

@end

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

@implementation TransitProxy {
    NSString* _proxyId;
}

-(id)initWithRootContext:(TransitContext*)rootContext proxyId:(NSString*)proxyId {
    self = [self init];
    if(self) {
        _rootContext = rootContext;
        _proxyId = proxyId;
    }
    return self;
}

-(id)initWithRootContext:(TransitContext*)rootContext {
    return [self initWithRootContext:rootContext proxyId:nil];
}

-(void)dealloc {
    [self dispose];
}

-(BOOL)disposed {
    return _rootContext == nil;
}

-(void)dispose {
    if(_rootContext) {
        if(_proxyId){
            [_rootContext releaseJSProxyWithId: _proxyId];
            _proxyId = nil;
        }
        _rootContext = nil;
    }
}

-(NSString*)proxyId {
    return _proxyId;
}

-(id)eval:(NSString*)jsCode {
    return [self eval:jsCode thisArg:nil arguments:@[]];
}

-(id)eval:(NSString*)jsCode arguments:(NSArray*)arguments {
    return [self eval:jsCode thisArg:nil arguments:arguments];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arguments:(NSArray*)arguments {
    @throw @"must be implemented by subclass";
}

-(NSString*)jsRepresentation {
    if(_proxyId && _rootContext)
       return [_rootContext jsRepresentationForProxyWithId:_proxyId];
    
    return [self.class jsRepresentation:self];
}

-(id)transitGlobalVarProxy {
    NSAssert(_rootContext, @"rootcontext not set");
    return _rootContext.transitGlobalVarProxy;
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
        
        id elem = mutableArguments[0];
        NSString* jsRepresentation = [elem respondsToSelector:@selector(jsRepresentation)] ? [elem performSelector:@selector(jsRepresentation)] : [self jsRepresentation:elem];
        NSString* result =  [NSString stringWithFormat:@"%@", jsRepresentation];
        
        [mutableArguments removeObjectAtIndex:0];
        return result;
    }];
    
    if(mutableArguments.count >0)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"too many arguments" userInfo:nil];
    
    return jsCode;
}

@end

@implementation TransitContext {
    NSMutableDictionary* _retainedProxies;
}

-(id)init {
    self = [super init];
    if(self){
        _retainedProxies = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)dealloc {
    // dispose manually from here to maintain correct life cycle
    [self disposeAllProxies];
}

-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId {
    return [TransitProxy jsExpressionFromCode:@"@.retained[@]" arguments:@[self.transitGlobalVarProxy, proxyId]];
}

-(void)disposeAllProxies {
    for (id proxy in _retainedProxies.allValues) {
        [proxy dispose];
    }
}

-(void)releaseJSProxyWithId:(NSString*)id {
    @throw @"not implemented, yet";
}

-(id)transitGlobalVarProxy {
    // TODO use root context if available
    return [TransitJSDirectExpression expression:@"transit"];
}

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

-(id)call {
    return [self callWithThisArg:nil arguments:@[]];
}

-(id)callWithArguments:(NSArray*)arguments {
    return [self callWithThisArg:nil arguments:arguments];
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments {
    @throw @"must be implemented by subclass";
}

@end

@implementation TransitNativeFunction

-(id)initWithRootContext:(TransitContext *)rootContext nativeId:(NSString*)nativeId block:(TransitFunctionBlock)block {
    self = [self initWithRootContext:rootContext];
    if(self) {
        NSParameterAssert(nativeId);
        NSParameterAssert(block);
        _nativeId = nativeId;
        _block = block;
    }
    return self;
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments {
    return _block(thisArg, arguments);
}

-(NSString*)jsRepresentation {
    return [TransitProxy jsExpressionFromCode:@"@.nativeFunction(@)" arguments:@[self.transitGlobalVarProxy, _nativeId]];
}

-(void)dispose {
    // explicit implementation needed to prevent compiler warning... weird
    [super dispose];
}

@end


@implementation TransitJSFunction

-(id)callWithThisArg:(id)thisArg arguments:(NSArray *)arguments {
    if(self.disposed)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"function already disposed" userInfo:nil];
    
    NSMutableArray *argumentsPlaceholder = [NSMutableArray array];
    while(argumentsPlaceholder.count<arguments.count)
          [argumentsPlaceholder addObject:@"@"];
    
    NSString* js = [NSString stringWithFormat:@"%@(%@)", self.jsRepresentation, [argumentsPlaceholder componentsJoinedByString:@","]];
    return [self.rootContext eval:js thisArg:thisArg arguments:arguments];
}

@end
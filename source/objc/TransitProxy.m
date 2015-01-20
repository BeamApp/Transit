//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitProxy.h"
#import "TransitCore.h"
#import "TransitContext+Private.h"
#import "SBJsonStreamWriterAccumulator.h"
#import "TransitObject+Private.h"
#import "TransitJSRepresentationStreamWriter.h"
#import "NSString+TransRegExp.h"

@implementation TransitProxy {
    NSString* _proxyId;
    id _value;
}

-(id)initWithContext:(TransitContext *)context proxyId:(NSString*)proxyId {
    self = [super initWithContext:context];
    if(self) {
        _proxyId = proxyId;
    }
    return self;
}

-(id)initWithContext:(TransitContext *)context value:(id)value {
    self = [super initWithContext:context];
    if(self){
        _value = value;
    }
    return self;
}

-(id)initWitContext:(TransitContext *)context jsRepresentation:(NSString*)jsRepresentation {
    return [self initWithContext:context value:transit_stringAsJSExpression(jsRepresentation)];
}


-(id)initWithContext:(TransitContext*)context {
    return [self initWithContext:context proxyId:nil];
}

-(void)dealloc {
    [self dispose];
}

-(BOOL)disposed {
    return self.context == nil;
}

-(void)clearContextAndProxyId {
    [self clearContext];
    _proxyId = nil;
}

-(void)dispose {
    if(self.context) {
        if(_proxyId){
            [self.context releaseJSProxyWithId:_proxyId];
        }
        [self clearContextAndProxyId];
    }
}

-(NSString*)proxyId {
    return _proxyId;
}

-(NSString*)jsRepresentationToResolveProxy {
    if(_proxyId && self.context)
        return [self.context jsRepresentationToResolveProxyWithId:_proxyId];

    @throw [NSException exceptionWithName:@"TransitException" reason:@"Internal Error: Proxy cannot be resolved" userInfo:nil];
}

-(NSString*)_jsRepresentationCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    if(_proxyId && self.context) {
        [proxiesOnScope addObject:self];
        return [self.context jsRepresentationForProxyWithId:_proxyId];
    }

    if(_value) {
        return [self.class jsRepresentation:_value collectingProxiesOnScope:proxiesOnScope];
    }

    return nil;
}

+(NSString*)jsRepresentation:(id)object collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    SBJsonStreamWriterAccumulator *accumulator = [[SBJsonStreamWriterAccumulator alloc] init];

	TransitJSRepresentationStreamWriter *streamWriter = [[TransitJSRepresentationStreamWriter alloc] init];
    streamWriter.delegate = accumulator;
    streamWriter.proxiesOnScope = proxiesOnScope;

    BOOL ok = [streamWriter writeValue:object];
    if(!ok) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"cannot be represented as JS (%@): %@", streamWriter.error, object] userInfo:nil];
    }

    return [NSString.alloc initWithData:accumulator.data encoding:NSUTF8StringEncoding];
}

+(NSString*)jsRepresentationFromCode:(NSString *)jsCode arguments:(NSArray *)arguments collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    if(transit_isJSExpression(jsCode)) {
        if(arguments.count > 0)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"jsExpression cannot take any additional arguments" userInfo:nil];
        return jsCode;
    }

    NSError* error;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"@"
                                  options:(NSRegularExpressionOptions) 0
                                  error:&error];

    NSMutableArray* mutableArguments = [arguments mutableCopy];
    jsCode = [jsCode transit_stringByReplacingMatchesOf:regex withTransformation:^(NSString *match) {
        if (mutableArguments.count <= 0)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"too few arguments" userInfo:nil];

        id elem = mutableArguments[0];
        NSString *jsRepresentation = [self jsRepresentation:elem collectingProxiesOnScope:proxiesOnScope];
        NSString *result = [NSString stringWithFormat:@"%@", jsRepresentation];

        [mutableArguments removeObjectAtIndex:0];
        return result;
    }];

    if(mutableArguments.count >0)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"too many arguments" userInfo:nil];

    return transit_stringAsJSExpression(jsCode);
}

@end

//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitNativeFunction.h"
#import "TransitCTBlockDescription.h"
#import "NSInvocation+TransitAdditions.h"
#import "TransitProxy+Private.h"
#import "TransitFunctionCallScope.h"
#import "TransitContext.h"
#import "TransitContext+Private.h"
#import "TransitFunctionBodyProtocol.h"

@implementation TransitNativeFunction

-(id)initWithContext:(TransitContext *)context nativeId:(NSString *)nativeId genericBlock:(TransitGenericFunctionBlock)block {
    self = [self initWithContext:context proxyId:nativeId];
    if(self) {
        NSParameterAssert(nativeId);
        NSParameterAssert(block);
        _block = [block copy];
    }
    return self;
}

+ (TransitGenericFunctionBlock)genericFunctionBlockWithDelegate:(id <TransitFunctionBodyProtocol>)delegate {
    return ^id(TransitNativeFunctionCallScope *scope) {
        return [delegate callWithFunction:scope.function thisArg:scope.thisArg arguments:scope.arguments expectsResult:scope.expectsResult];
    };
}

+ (void)assertSpecificBlockCanBeUsedAsTransitFunction:(id)block {
    if(![block isKindOfClass:NSClassFromString(@"NSBlock")])
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"expected block but was %@", NSStringFromClass([block class])] userInfo:nil];

    TransitCTBlockDescription *desc = [TransitCTBlockDescription.alloc initWithBlock:block];
    NSMethodSignature *sig = desc.blockSignature;

    void(^assertValidType)(char const*, NSString*) = ^(char const* typeChar, NSString* suffix){
        if(strchr("cislqCISLQfdBv@", typeChar[0]) == NULL)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"unsupported type %c for %@", typeChar[0], suffix] userInfo:nil];
    };

    assertValidType(sig.methodReturnType, @"return type");
    for(NSUInteger i=0;i<sig.numberOfArguments;i++)
        assertValidType([sig getArgumentTypeAtIndex:i], [NSString stringWithFormat:@"argument at index %ld", (unsigned long)i]);
}

+ (TransitGenericFunctionBlock)genericFunctionBlockWithBlock:(id)block {
    // additional runtime-check, in case TRANSIT_SPECIFIC_BLOCKS_SUPPORTED has been overriden (e.g. for unit tests)
    if(!transit_specificBlocksSupported())
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"specific blocks are not supported on this version/platform" userInfo:nil];

    [self assertSpecificBlockCanBeUsedAsTransitFunction:block];
    return ^id(TransitNativeFunctionCallScope *callScope) {
        TransitCTBlockDescription *desc = [TransitCTBlockDescription.alloc initWithBlock:block];
        NSMethodSignature *sig = desc.blockSignature;
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];

        // arg 0 of invocation is self and will be block
        for(NSUInteger i=0;i<MIN(sig.numberOfArguments-1, callScope.arguments.count);i++)
            [inv transit_setObject:callScope.arguments[i] forArgumentAtIndex:i + 1];

//        // this would work on iOS5 but is private API
//        // should there be another pre compiler flag to allow them?
//        inv.target = block;
//        void* impl = ((__bridge struct TransitCTBlockLiteral *)block)->invoke;
//        [inv invokeUsingIMP:impl];

        // does not work on iOS 5
        [inv invokeWithTarget:block];
        return inv.transit_returnValueAsObject;
    };
}


-(id)_callWithScope:(TransitNativeFunctionCallScope *)scope {
    return _block(scope);
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments returnResult:(BOOL)returnResult {
    id result = [self.context invokeNativeFunc:self thisArg:thisArg arguments:arguments expectsResult:returnResult];
    return returnResult ? result : nil;
}

-(NSString*)_jsRepresentationCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    [proxiesOnScope addObject:self];
    return [self.context jsRepresentationForNativeFunctionWithId:self.proxyId];
}

-(NSString*)jsRepresentationToResolveProxy {
    return [self.context jsRepresentationToResolveNativeFunctionWithId:self.proxyId async:self.async noThis:self.noThis];
}

-(void)dispose {
    if(self.context) {
        if(self.proxyId)
            [self.context releaseNativeFunction:self];
        [self clearContextAndProxyId];
    }
}

@end

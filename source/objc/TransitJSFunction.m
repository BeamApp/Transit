//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.#import "TransitEvaluator.h"
//

#import "TransitJSFunction.h"
#import "TransitCallScope.h"
#import "TransitAbstractWebViewContext.h"
#import "TransitEvaluator.h"
#import "TransitFunctionCallScope.h"
#import "TransitFunctionCallScope+Private.h"
#import "TransitProxy+Private.h"
#import "TransitCore.h"
#import "TransitContext+Private.h"

@implementation TransitJSFunction

- (id)onEvaluator:(id <TransitEvaluator>)evaluator callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult buildCallScope:(BOOL)buildCallScope {
    if(self.disposed)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"function already disposed" userInfo:nil];

    BOOL noSpecificThisArg = (thisArg == nil) || (thisArg == self.context);

    TransitCallScope *callScope;
    if(buildCallScope) {
        callScope = [TransitJSFunctionCallScope.alloc initWithContext:self.context parentScope:self.context.currentCallScope thisArg:thisArg arguments:arguments expectsResult:returnResult function:self];
    }

    if(noSpecificThisArg) {
        // most frequent cases: zore or one argument, no specific this arg
        NSMutableOrderedSet *proxiesOnScope = [NSMutableOrderedSet orderedSet];
        NSString* jsFunc = [self _jsRepresentationCollectingProxiesOnScope:proxiesOnScope];
        NSMutableArray* jsArgs = [NSMutableArray arrayWithCapacity:arguments.count];
        for(id arg in arguments) {
            [jsArgs addObject:[TransitProxy jsRepresentation:arg collectingProxiesOnScope:proxiesOnScope]];
        }
        NSString* jsCall = [NSString stringWithFormat:@"%@(%@)", jsFunc, [jsArgs componentsJoinedByString:@","]];

        return [evaluator _eval:jsCall jsThisArg:@"null" collectedProxiesOnScope:proxiesOnScope returnJSResult:returnResult onGlobalScope:NO useAndRestoreCallScope:callScope];
    } else {
        // general case
        return [evaluator _eval:@"@.apply(@,@)" thisArg:nil values:@[self, TransitNilSafe(thisArg), (arguments ? arguments : @[])] returnJSResult:returnResult useAndRestoreCallScope:callScope];
    }
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult {
    return [self onEvaluator:self.context callWithThisArg:thisArg arguments:arguments returnResult:returnResult buildCallScope:YES];
}

// remove this method if you do not want to call async JS functions in bulk
-(void)callAsyncWithThisArg:(id)thisArg arguments:(NSArray*)arguments {
    [self.context queueAsyncCallToJSFunction:self thisArg:thisArg arguments:arguments];
}

@end

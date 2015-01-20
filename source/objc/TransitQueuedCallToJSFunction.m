//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitQueuedCallToJSFunction.h"
#import "TransitJSFunction.h"
#import "Transit+Private.h"
#import "TransitProxy+Private.h"
#import "TransitJSFunction+Private.h"

@implementation TransitQueuedCallToJSFunction {
    TransitJSFunction* _jsFunc;
    id _thisArg;
    NSArray* _arguments;
    NSString*__collectedJS;
    NSOrderedSet*__collectedProxiesOnScope;
}

-(id)initWithJSFunction:(TransitJSFunction*)jsFunc thisArg:(id)thisArg arguments:(NSArray*)arguments {
    self = [self init];
    if(self) {
        _jsFunc = jsFunc;
        _thisArg = thisArg;
        _arguments = arguments;
    }
    return self;
}

-(NSString*)jsRepresentationOfCallCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    [_jsFunc onEvaluator:self callWithThisArg:_thisArg arguments:_arguments returnResult:NO buildCallScope:NO];
    [proxiesOnScope addObjectsFromArray:__collectedProxiesOnScope.array];
    return __collectedJS;
}

- (id)_eval:(NSString *)jsExpression jsThisArg:(NSString *)jsAdjustedThisArg collectedProxiesOnScope:(NSOrderedSet *)proxiesOnScope returnJSResult:(BOOL)returnJSResult onGlobalScope:(BOOL)globalScope useAndRestoreCallScope:(TransitCallScope *)callScope {
    __collectedProxiesOnScope = proxiesOnScope;

    if([@"null" isEqualToString:jsAdjustedThisArg]) {
        __collectedJS = [NSString stringWithFormat:@"%@;", jsExpression];
    } else {
        __collectedJS = [NSString stringWithFormat:@"(function(){%@}).apply(%@);", jsExpression, jsAdjustedThisArg];
    }
    return nil;
}

- (id)_eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)arguments returnJSResult:(BOOL)returnJSResult useAndRestoreCallScope:(TransitCallScope *)callScope {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;

    NSString* jsExpression = [TransitProxy jsRepresentationFromCode:jsCode arguments:arguments collectingProxiesOnScope:proxiesOnScope];
    id adjustedThisArg = thisArg == _jsFunc.context ? nil : thisArg;
    NSString* jsAdjustedThisArg = adjustedThisArg ? [TransitProxy jsRepresentation:thisArg collectingProxiesOnScope:proxiesOnScope] : @"null";

    return [self _eval:jsExpression jsThisArg:jsAdjustedThisArg collectedProxiesOnScope:proxiesOnScope returnJSResult:returnJSResult onGlobalScope:NO useAndRestoreCallScope:callScope];
}


@end

//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.#import "TransitContext.h"
//

#import "TransitEvalCallScope.h"
#import "TransitCallScope+Private.h"

@implementation TransitEvalCallScope : TransitCallScope

- (id)initWithContext:(TransitContext *)parentScope parentScope:(TransitCallScope *)scope thisArg:(id)thisArg jsCode:(NSString *)jsCode values:(NSArray *)values expectsResult:(BOOL)expectsResult {
    self = [self initWithContext:parentScope parentScope:scope thisArg:thisArg expectsResult:expectsResult];
    if(self) {
        _jsCode = [jsCode copy];
        _values = [values copy];
    }
    return self;
}

- (NSString *)callStackFrameDescription {
    return [NSString stringWithFormat:@"%@ %@ -- values:(%@)", self.description, self.jsCode, [self.values componentsJoinedByString:@", "]];
}

@end

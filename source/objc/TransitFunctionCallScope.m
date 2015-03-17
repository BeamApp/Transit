//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitFunctionCallScope.h"
#import "TransitFunction.h"
#import "TransitCallScope+Private.h"
#import "TransitCore.h"
#import "TransitFunctionBodyProtocol.h"

@implementation TransitFunctionCallScope : TransitCallScope

- (id)initWithContext:(TransitContext *)context parentScope:(TransitCallScope *)parentScope thisArg:(id)arg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult function:(TransitFunction *)function {
    self = [self initWithContext:context parentScope:parentScope thisArg:arg expectsResult:expectsResult];
    if(self) {
        _function = function;
        _arguments = [arguments copy];
    }
    return self;
}

- (id)objectForImplicitVars {
    return self.thisArg;
}

- (id)forwardToFunction:(TransitFunction *)function {
    return [function callWithThisArg:self.thisArg arguments:self.arguments returnResult:self.expectsResult];
}

-(id)forwardToDelegate:(id<TransitFunctionBodyProtocol>)delegate {
    return [delegate callWithFunction:self.function thisArg:self.thisArg arguments:self.arguments expectsResult:self.expectsResult];
}

- (NSString *)callStackFrameDescription {
    return [NSString stringWithFormat:@"%@(%@)", self.description, [self.arguments componentsJoinedByString:@", "]];
}

@end

@implementation TransitJSFunctionCallScope : TransitFunctionCallScope
@end

@implementation TransitNativeFunctionCallScope : TransitFunctionCallScope
@end

//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitEvaluable.h"

@class TransitCallScope;

/// State for the current call of a TransitNativeFunction
// @see TransitCurrentCall
@interface TransitCallScope : TransitEvaluable

@property (nonatomic, readonly) TransitCallScope *parentScope;
@property (nonatomic, readonly) id thisArg;
@property (nonatomic, readonly) BOOL expectsResult;
@property (nonatomic, readonly) NSUInteger level;

-(NSString*)callStackDescription;

@end

/// Implicitly created on asynchrounous call.
@interface TransitAsyncCallScope : TransitCallScope
@end

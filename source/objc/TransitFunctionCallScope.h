//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitCallScope.h"

@class TransitFunction;
@protocol TransitFunctionBodyProtocol;

/// Super type of native and JavaScript function calls. Created whenever a function is called from native code or JavaScript.
@interface TransitFunctionCallScope : TransitCallScope

@property (nonatomic, readonly) TransitFunction *function;
@property (nonatomic, readonly) NSArray* arguments;

/// Forwards current call to another TransitFunction. Preservers all arguments and thisArg.
/// @param function To be called.
/// @returns Result of called TransitFunction.
-(id)forwardToFunction:(TransitFunction *)function;

-(id)forwardToDelegate:(id<TransitFunctionBodyProtocol>)delegate;

@end

/// Created when calling a TransitJSFunction function from native code or JavaScript.
@interface TransitJSFunctionCallScope : TransitFunctionCallScope
@end

/// Created when calling a TransitNativeFunction function from native code or JavaScript.
@interface TransitNativeFunctionCallScope : TransitFunctionCallScope
@end

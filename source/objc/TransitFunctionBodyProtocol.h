//
// Created by Marcel Jackwerth on 20/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

@class TransitFunction;

/// Protocol to provide native implementations for [TransitContext functionWithDelegate:]
@protocol TransitFunctionBodyProtocol <NSObject>

/// Called [TransitFunction call].
/// @param function Reference to TransitFunction this is the implementation for.
/// @param thisArg JavaScript's this argument.
/// @param arguments Array if arguments passed to the function.
/// @param expectsResult YES, if call expects to return a result. Can be NO on async calls.
- (id)callWithFunction:(TransitFunction *)function thisArg:(id)thisArg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult;
@end

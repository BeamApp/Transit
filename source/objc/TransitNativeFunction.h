//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitFunction.h"
#import "TransitCore.h"

/// Function that represents native implementation.
@interface TransitNativeFunction : TransitFunction

/// Call dispose to explicitly release native function.
-(void)dispose;

/// TRUE, if calls can be executed aynchronous. Can increase performance.
@property(nonatomic, assign) BOOL async;

/// TRUE, if this arg is not needed. Can increase performance.
@property(nonatomic, assign) BOOL noThis;

/// Block that represents native implementation. Will always be a block, even if created with [TransitContext functionWithDelegate:].
@property(readonly) TransitGenericFunctionBlock block;

@end

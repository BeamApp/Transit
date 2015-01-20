//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//


#ifndef __TransitContext_H_
#define __TransitContext_H_

#import "TransitEvaluable.h"

@class TransitNativeFunction;
@class TransitFunction;
@class TransitNativeFunctionCallScope;
@protocol TransitFunctionBodyProtocol;
@class TransitCallScope;

/// Represents JavaScript environment.
@interface TransitContext : TransitEvaluable

-(TransitFunction*)functionWithGenericBlock:(id (^)(TransitNativeFunctionCallScope *))block;

/// Creates a new TransitNativeFunction based on a protocol.
/// @param delegate Method implementation.
-(TransitFunction*)functionWithDelegate:(id<TransitFunctionBodyProtocol>)delegate;
-(TransitFunction*)replaceFunctionAt:(NSString *)path withGenericBlock:(id (^)(TransitFunction *, TransitNativeFunctionCallScope *))block;
-(TransitFunction*)asyncFunctionWithGenericBlock:(void (^)(TransitNativeFunctionCallScope *))block;

-(TransitFunction*)functionWithBlock:(id)block;// NS_AVAILABLE(10_8, 6_0);
-(TransitFunction*)replaceFunctionAt:(NSString *)path withBlock:(id)block;// NS_AVAILABLE(10_8, 6_0);

@property(nonatomic, readonly) TransitCallScope* currentCallScope;

-(void)dispose;

@property(nonatomic, copy) void (^readyHandler)(TransitContext *);

- (id)invokeNativeFunc:(TransitNativeFunction *)func thisArg:(id)thisArg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult;

- (BOOL)evalContentsOfFileOnGlobalScope:(NSString *)path encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (void)evalOnGlobalScope:(NSString *)string;

@end

#import "TransitObject.h"

#endif //__TransitContext_H_

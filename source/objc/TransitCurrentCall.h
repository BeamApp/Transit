//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//


#ifndef __TransitCurrentCall_H_
#define __TransitCurrentCall_H_

@class TransitContext;
@class TransitFunctionCallScope;
@class TransitFunction;

TransitContext *_TransitCurrentCall_currentContext;
TransitFunction *_TransitCurrentCall_originalFunctionForCurrentCall;

/// Singleton to access state for current call to TransitNativeFunction.
@interface TransitCurrentCall : NSObject

+(TransitContext *)context;
+(TransitFunctionCallScope *)callScope;
+(id)thisArg;
+(NSArray*)arguments;
+(TransitFunction *)replacedFunction;

+(id)forwardToReplacedFunction;

@end

#import "TransitObject.h"

#endif //__TransitCurrentCall_H_

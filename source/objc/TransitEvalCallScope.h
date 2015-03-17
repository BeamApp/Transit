//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//


#ifndef __TransitEvalCallScope_H_
#define __TransitEvalCallScope_H_

#import "TransitCallScope.h"

/// Created when calling any [TransitEvaluable eval:].
@interface TransitEvalCallScope : TransitCallScope

@property (nonatomic, readonly) NSString* jsCode;
@property (nonatomic, readonly) NSArray* values;

@end

#endif //__TransitEvalCallScope_H_

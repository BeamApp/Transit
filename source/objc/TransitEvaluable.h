//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//


#ifndef __TransitEvaluable_H_
#define __TransitEvaluable_H_

#import "TransitObject.h"

/// Baseclass on anything you can evaluate JavaScript on.
@interface TransitEvaluable : TransitObject

/// Various convenience methods.
/// @param jsCode String with actual JavaScript code.
-(id)eval:(NSString*)jsCode;
-(id)eval:(NSString *)jsCode val:(id)val0;
-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1;
-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1 val:(id)val2;
-(id)eval:(NSString *)jsCode values:(NSArray*)values;

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0 val:(id)val1;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray*)values;

/// Evaluates Javascript in the context of this object.
/// @param jsCode String with actual JavaScript code.
/// @param thisArg Explicit reference to JavaScript this if not nil. Other convenience methods will pass nil.
/// @param values Array of arguments.
/// @param returnJSResult YES, if result expected. Passing NO can increase performance. Other convenience methods will pass YES.
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)values returnJSResult:(BOOL)returnJSResult;

@end

#endif //__TransitEvaluable_H_

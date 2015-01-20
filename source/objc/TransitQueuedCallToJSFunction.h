//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransitEvaluator.h"

@class TransitJSFunction;

@interface TransitQueuedCallToJSFunction : NSObject<TransitEvaluator>

-(id)initWithJSFunction:(TransitJSFunction*)jsFunc thisArg:(id)thisArg arguments:(NSArray*)arguments;
-(NSString*)jsRepresentationOfCallCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;

@end

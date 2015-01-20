//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (TransitAdditions)

-(void)transit_setObject:(id)object forArgumentAtIndex:(NSUInteger)index;
-(id)transit_returnValueAsObject;

@end

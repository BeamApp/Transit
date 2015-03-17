//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TransitContext;

/// TransitObject builds the foundation for many objects represented in the JavaScript environment.
@interface TransitObject : NSObject

/// The TransitContext this object belongs to. On TransitContext this property points to itself.
-(TransitContext*)context;

/// @name Accessing Properties of Object

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id < NSCopying >)key;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)object atIndexedSubscript:(NSInteger)index;
- (id)objectForKeyedSubscript:(id)key;
 - (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key;

/// @name Calling Methods on Object

- (id)callMember:(NSString *)key;
- (id)callMember:(NSString *)key arg:(id)arg0;
- (id)callMember:(NSString *)key arg:(id)arg0 arg:(id)arg1;
- (id)callMember:(NSString *)key arg:(id)arg0 arg:(id)arg1 arg:(id)arg2;
- (id)callMember:(NSString *)key arguments:(NSArray *)arguments;

@end

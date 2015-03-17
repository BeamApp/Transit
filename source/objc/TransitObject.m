//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.#import "TransitContext.h"
//

#import "TransitObject.h"
#import "TransitContext.h"

@implementation TransitObject{
    __weak TransitContext *_context;
}

-(id)initWithContext:(TransitContext*)context {
    self = [self init];
    if(self) {
        _context = context;
    }
    return self;
}

-(TransitContext*)context {
    return _context;
}

- (void)clearContext {
    _context = nil;
}

- (id)objectForImplicitVars {
    return self;
}

- (id)objectForKey:(id)key{
    return [self.context eval:@"@[@]" val:self.objectForImplicitVars val:key];
}

- (void)setObject:(id)object forKey:(id < NSCopying >)key {
    [self.context eval:@"@[@]=@" val:self.objectForImplicitVars val:key val:object];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return [self objectForKey:@(idx)];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSInteger)idx {
    [self setObject:obj forKey:@(idx)];
}

- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    [self setObject:obj forKey:key];
}

- (id)callMember:(NSString *)string {
    return [self callMember:string arguments:@[]];
}

- (id)callMember:(NSString *)string arg:(id)arg0 {
    return [self callMember:string arguments:@[arg0]];
}

- (id)callMember:(NSString *)string arg:(id)arg0 arg:(id)arg1 {
    return [self callMember:string arguments:@[arg0, arg1]];
}

- (id)callMember:(NSString *)string arg:(id)arg0 arg:(id)arg1 arg:(id)arg2 {
    return [self callMember:string arguments:@[arg0, arg1, arg2]];
}

- (id)callMember:(NSString *)string arguments:(NSArray *)arguments {
    return [self.context eval:@"@[@].apply(@,@)" values:@[self, string, self, arguments]];
}

@end

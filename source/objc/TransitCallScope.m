//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.#import "TransitContext.h"
//

#import "TransitCallScope.h"
#import "TransitNativeFunction.h"
#import "TransitObject+Private.h"

@implementation TransitCallScope

- (id)initWithContext:(TransitContext *)context parentScope:(TransitCallScope *)parentScope thisArg:(id)thisArg expectsResult:(BOOL)expectsResult {
    self = [self initWithContext:context];
    if(self) {
        _parentScope = parentScope;
        _thisArg = thisArg ? thisArg : context;
        _expectsResult = expectsResult;
    }
    return self;
}

-(NSUInteger)level {
    return self.parentScope.level + 1;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%.3ld %@(this=%@)", (unsigned long)self.level, NSStringFromClass(self.class), self.thisArg];
}

- (NSString *)callStackDescription {
    NSMutableArray *stackSymbols = NSMutableArray.new;
    TransitCallScope *scope = self;
    while(scope) {
        [stackSymbols addObject:scope.callStackFrameDescription];
        scope = scope.parentScope;
    }

    return [stackSymbols componentsJoinedByString:@"\n"];
}

- (NSString *)callStackFrameDescription {
    return [NSString stringWithFormat:@"unkown call frame %@", NSStringFromClass(self.class)];
}

@end

@implementation TransitAsyncCallScope : TransitCallScope
@end

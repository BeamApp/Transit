//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "NSInvocation+TransitAdditions.h"

@implementation NSInvocation (TransitAdditions)

-(void)transit_setObject:(id)object forArgumentAtIndex:(NSUInteger)index {
    const char* argType = [self.methodSignature getArgumentTypeAtIndex:index];
    switch(argType[0]) {
        //cislqCISLQfdBv@
        case 'c': {
            char value = [object charValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'i': {
            int value = [object intValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 's': {
            short value = [object shortValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'l': {
            long value = [object longValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'q': {
            long long value = [object longLongValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'C': {
            unsigned char value = [object unsignedCharValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'I': {
            unsigned int value = [object unsignedIntValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'S': {
            unsigned short value = [object unsignedShortValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'L': {
            unsigned long value = [object unsignedLongValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'Q': {
            unsigned long long value = [object unsignedLongLongValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'f': {
            float value = [object floatValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'd': {
            double value = [object doubleValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case 'B': {
            BOOL value = [object boolValue];
            [self setArgument:&value atIndex:index];
            return;
        }
        case '@': {
            id value = object;
            [self setArgument:&value atIndex:index];
            return;
        }
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"unsupported type %c for argument at index %ld", argType[0], (unsigned long)index] userInfo:nil];
    }
}

-(id)transit_returnValueAsObject {
    if(self.methodSignature.methodReturnLength<=0)
        return nil;

    const char* argType = [self.methodSignature methodReturnType];
    switch(argType[0]) {
        //cislqCISLQfdBv@
        case 'c': {
            char value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'i': {
            int value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 's': {
            short value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'l': {
            long value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'q': {
            long long value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'C': {
            unsigned char value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'I': {
            unsigned int value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'S': {
            unsigned short value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'L': {
            unsigned long value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'Q': {
            unsigned long long value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'f': {
            float value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'd': {
            double value;
            [self getReturnValue:&value];
            return @(value);
        }
        case 'B': {
            BOOL value;
            [self getReturnValue:&value];
            return @(value);
        }
        case '@': {
            __unsafe_unretained id value;
            [self getReturnValue:&value];
            return value;
        }
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"unsupported type %c for return type", argType[0]] userInfo:nil];
    }
}

@end

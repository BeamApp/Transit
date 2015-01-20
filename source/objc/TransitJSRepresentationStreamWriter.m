//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <SBJson/SBJsonStreamWriterState.h>
#import "TransitJSRepresentationStreamWriter.h"
#import "TransitProxy+Private.h"
#import "TransitCore.h"

@implementation TransitJSRepresentationStreamWriter

-(BOOL)writeValue:(id)value {
    // nil -> undefined
    if(value == nil)
        return [self writeJSExpression:@"undefined"];

    // NSString marked as jsExpression -> jsEpxression
    if([value isKindOfClass:NSString.class] && transit_isJSExpression(value))
        return [self writeJSExpression:value];

    // TransitProxy -> must provide own representation
    if([value isKindOfClass:TransitProxy.class]) {
        TransitProxy* proxy = (TransitProxy*)value;
        NSString* jsRepresentation = [proxy _jsRepresentationCollectingProxiesOnScope:self.proxiesOnScope];
        if(jsRepresentation == nil) {
            self.error = [NSString stringWithFormat:@"TransitProxy %@ has no jsRepresentation", value];
            return NO;
        }

        return [self writeJSExpression:jsRepresentation];
    }
    // NSError -> new Error(desc)
    if([value isKindOfClass:NSError.class]) {
        NSString* desc = [value userInfo][NSLocalizedDescriptionKey];
        NSString* jsExpression = [NSString stringWithFormat:@"new Error(%@)", [TransitProxy jsRepresentation:desc collectingProxiesOnScope:self.proxiesOnScope]];
        return [self writeJSExpression:jsExpression];
    }

    // any valid JSON value
    return [super writeValue:value];
}

-(BOOL)writeJSExpression:(NSString*)jsExpression {
    if ([self.state isInvalidState:self]) return NO;
    if ([self.state expectingKey:self]) return NO;
    [self.state appendSeparator:self];
    if (self.humanReadable) [self.state appendWhitespace:self];

    NSData *data = [jsExpression dataUsingEncoding:NSUTF8StringEncoding];
    [self.delegate writer:self appendBytes:data.bytes length:data.length];

    [self.state transitionState:self];
    return YES;
}

@end

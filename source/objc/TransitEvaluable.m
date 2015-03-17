//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitEvaluable.h"
#import "TransitCore.h"
#import "TransitContext+Private.h"

@implementation TransitEvaluable : TransitObject

-(id)eval:(NSString*)jsCode {
    return [self eval:jsCode thisArg:self values:@[] returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode val:(id)val0 {
    return [self eval:jsCode thisArg:self values:@[TransitNilSafe(val0)] returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1 {
    return [self eval:jsCode thisArg:self values:@[TransitNilSafe(val0), TransitNilSafe(val1)] returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1 val:(id)val2 {
    return [self eval:jsCode thisArg:self values:@[TransitNilSafe(val0), TransitNilSafe(val1), TransitNilSafe(val2)] returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode values:(NSArray*)values {
    return [self eval:jsCode thisArg:self values:values returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg {
    return [self eval:jsCode thisArg:thisArg values:@[] returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0 {
    return [self eval:jsCode thisArg:thisArg values:@[TransitNilSafe(val0)] returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0 val:(id)val1 {
    return [self eval:jsCode thisArg:thisArg values:@[TransitNilSafe(val0), TransitNilSafe(val1)] returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray*)values {
    return [self eval:jsCode thisArg:thisArg values:values returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)values returnJSResult:(BOOL)returnJSResult {
    return [self.context eval:jsCode thisArg:thisArg values:values returnJSResult:returnJSResult];
}

@end

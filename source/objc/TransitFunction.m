//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitContext.h"
#import "TransitFunction.h"
#import "TransitCore.h"

@implementation TransitFunction

-(id)call {
    return [self callWithThisArg:nil arguments:@[] returnResult:YES];
}

-(id)callWithArg:(id)arg0 {
    return [self callWithThisArg:nil arguments:@[TransitNilSafe(arg0)] returnResult:YES];
}

-(id)callWithArg:(id)arg0 arg:(id)arg1 {
    return [self callWithThisArg:nil arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)] returnResult:YES];
}

-(id)callWithArg:(id)arg0 arg:(id)arg1 arg:(id)arg2 {
    return [self callWithThisArg:nil arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1), TransitNilSafe(arg2)] returnResult:YES];
}

-(id)callWithArguments:(NSArray*)arguments {
    return [self callWithThisArg:nil arguments:arguments returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg {
    return [self callWithThisArg:thisArg arguments:@[] returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arg:(id)arg0 {
    return [self callWithThisArg:thisArg arguments:@[TransitNilSafe(arg0)] returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arg:(id)arg0 arg:(id)arg1 {
    return [self callWithThisArg:thisArg arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)] returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments {
    return [self callWithThisArg:thisArg arguments:arguments returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult {
    @throw [NSException exceptionWithName:@"Abstract" reason:@"must be implemented by subclass" userInfo:nil];;
}

-(void)callAsync {
    [self callAsyncWithThisArg:nil arguments:@[]];
}

-(void)callAsyncWithArg:(id)arg0 {
    [self callAsyncWithThisArg:nil arguments:@[TransitNilSafe(arg0)]];
}

-(void)callAsyncWithArg:(id)arg0 arg:(id)arg1 {
    [self callAsyncWithThisArg:nil arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)]];
}

-(void)callAsyncWithArguments:(NSArray*)arguments {
    [self callAsyncWithThisArg:nil arguments:arguments];
}

-(void)callAsyncWithThisArg:(id)thisArg arguments:(NSArray*)arguments {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self callWithThisArg:thisArg arguments:arguments returnResult:NO];
    });
}


@end

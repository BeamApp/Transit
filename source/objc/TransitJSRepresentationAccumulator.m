//
//  TransitJSRepresentationAccumulator.m
//  TransitTestsIOS
//
//  Created by Marcel Jackwerth on 22/01/15.
//  Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitJSRepresentationAccumulator.h"

@implementation TransitJSRepresentationAccumulator {
    NSMutableData *_data;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _data = [NSMutableData new];
    }
    
    return self;
}

- (void)writer:(SBJson4StreamWriter *)writer appendBytes:(const void *)bytes length:(NSUInteger)length {
    [_data appendBytes:bytes length:length];
}

- (NSData *)data {
    return [NSData dataWithData:_data];
}

@end

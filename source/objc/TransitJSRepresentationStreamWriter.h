//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <SBJson/SBJsonStreamWriter.h>

@interface TransitJSRepresentationStreamWriter : SBJsonStreamWriter

@property (nonatomic, unsafe_unretained) SBJsonStreamWriterState *state; // Internal
@property(nonatomic, strong) NSMutableOrderedSet* proxiesOnScope;

@end

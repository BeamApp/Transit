//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <SBJson4/SBJson4StreamWriter.h>

@interface TransitJSRepresentationStreamWriter : SBJson4StreamWriter

@property(nonatomic, strong) NSMutableOrderedSet* proxiesOnScope;

@end

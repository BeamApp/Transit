//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(TransRegExp)

-(NSString*)transit_stringByReplacingMatchesOf:(NSRegularExpression *)regex withTransformation:(NSString*(^)(NSString*element)) block;

@end

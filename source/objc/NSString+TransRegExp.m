//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "NSString+TransRegExp.h"

@implementation NSString(TransRegExp)

-(NSString*)transit_stringByReplacingMatchesOf:(NSRegularExpression *)regex withTransformation:(NSString*(^)(NSString*element)) block {

    NSMutableString* mutableString = [self mutableCopy];
    NSInteger offset = 0;

    for (NSTextCheckingResult* result in [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)]) {

        NSRange resultRange = [result range];
        resultRange.location += offset;

        NSString* match = [regex replacementStringForResult:result
                                                   inString:mutableString
                                                     offset:offset
                                                   template:@"$0"];

        NSString* replacement = block(match);

        // make the replacement
        [mutableString replaceCharactersInRange:resultRange withString:replacement];

        // update the offset based on the replacement
        offset += ([replacement length] - resultRange.length);
    }
    return mutableString;
}

@end

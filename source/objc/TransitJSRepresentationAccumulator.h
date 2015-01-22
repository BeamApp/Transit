//
//  TransitJSRepresentationAccumulator.h
//  TransitTestsIOS
//
//  Created by Marcel Jackwerth on 22/01/15.
//  Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SBJson4/SBJson4StreamWriter.h>

@interface TransitJSRepresentationAccumulator : NSObject<SBJson4StreamWriterDelegate>

- (NSData *)data;

@end

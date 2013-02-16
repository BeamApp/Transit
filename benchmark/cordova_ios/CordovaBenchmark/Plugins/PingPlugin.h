//
//  PingPlugin.h
//  benchmark
//
//  Created by Connor Dunn on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface PingPlugin : CDVPlugin {
}

//Instance Method  
- (void) ping:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end

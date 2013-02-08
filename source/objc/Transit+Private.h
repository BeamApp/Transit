//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Transit.h"

@interface TransitProxy(Private)

-(void)dispose;
-(BOOL)disposed;

@property(readonly) NSString* proxyId;

@end

@interface TransitContext(Private)

-(void)releaseProxy:(TransitProxy*)proxy;
-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId;

@end


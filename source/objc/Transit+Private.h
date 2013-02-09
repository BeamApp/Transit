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
-(TransitProxy*)transitGlobalVarProxy;

@property(readonly) NSString* proxyId;

@end

@interface TransitContext(Private)

@property (readonly) NSMutableDictionary* retainedProxies;

-(void)releaseJSProxyWithId:(NSString*)proxy;
-(void)releaseNativeProxy:(TransitProxy*)proxy;

-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId;

@end

@interface TransitJSDirectExpression : NSObject

-(id)initWithExpression:(NSString*)expression;

@property(readonly) NSString* expression;

@end

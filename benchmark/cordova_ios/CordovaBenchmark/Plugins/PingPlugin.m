//
//  PingPlugin.m
//  benchmark
//
//  Created by Connor Dunn on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PingPlugin.h"

@implementation PingPlugin

-(void)ping:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options  
{
	
	//The first argument in the arguments parameter is the callbackID.
	//We use this to send data back to the successCallback or failureCallback
	//through PluginResult.   
	NSString *callbackID = [arguments pop];
	
	//Get the string that javascript sent us 
	NSString *stringObtainedFromJavascript = [arguments objectAtIndex:0];                 

	//Create Plugin Result
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:stringObtainedFromJavascript];
	//Call  the Success Javascript function
	[self writeJavascript: [pluginResult toSuccessCallbackString:callbackID]];

	
}

@end

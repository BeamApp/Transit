//
//  AppDelegate.h
//  TransitExampleOSX
//
//  Created by Heiko Behrens on 02.07.13.
//  Copyright (c) 2013 BeamApp UG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Transit.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (readonly) TransitContext *context;
@property (weak) IBOutlet WebView *webView;

@end

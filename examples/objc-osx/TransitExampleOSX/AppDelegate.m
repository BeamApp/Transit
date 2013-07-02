//
//  AppDelegate.m
//  TransitExampleOSX
//
//  Created by Heiko Behrens on 02.07.13.
//  Copyright (c) 2013 BeamApp UG. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

CGSize ds = {.width = 363, .height = 665};

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window setFrame: CGRectMake(self.window.frame.origin.x, self.window.frame.origin.y, ds.width, ds.height) display:YES];
    
    _context = [TransitWebViewContext contextWithWebView:self.webView];
    [_context replaceFunctionAt:@"setTimeout" withBlock:^(TransitFunction *f, int delay){
        // no dedicated entry point, this is the best I could find
        if(delay == 250) {
            [self performSelector:@selector(setupTransit) withObject:nil afterDelay:2];
            TransitCurrentCall.context[@"setTimeout"] = TransitCurrentCall.replacedFunction;
        }
        return [TransitCurrentCall forwardToReplacedFunction];
    }];

    // load unmodified game from web
    NSURL *url = [NSURL URLWithString:@"http://phoboslab.org/ztype/"];
    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)setupTransit {
    __weak AppDelegate* __self = self;
    
    [_context replaceFunctionAt:@"ig.game.drawUI" withBlock:^{
        __self.window.title = [[__self.context eval:@"ig.game.score"] description];
        return [TransitCurrentCall forwardToReplacedFunction];
    }];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    return CGSizeMake(ds.width, ds.height);
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


@end

//
//  ForgeBenchmarkViewController.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 10.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "ForgeBenchmarkViewController.h"
#import "Transit.h"
#import "Transit+Private.h"

@interface ForgeBenchmarkViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) TransitContext *transit;

@end

@implementation ForgeBenchmarkViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.title = @"Forge Benchmark";
    }
    return self;
}


- (void)viewDidLoad
{
    // this VC embed the benchmark from trigger.io
    // https://github.com/trigger-corp/Forge-vs-Cordova-Performance/blob/master/Forge/benchmark/index.html
    // read about it here
    // http://trigger.io/cross-platform-application-development-blog/2012/02/24/why-trigger-io-doesnt-use-phonegap-5x-faster-native-bridge/         
    
    [super viewDidLoad];
    NSURL *url = [NSBundle.mainBundle URLForResource:@"forge_benchmark" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self setupTransit];
}

-(void)setupTransit {
    self.transit = [[TransitUIWebViewContext alloc] initWithUIWebView:self.webView];
    
    TransitNativeFunction *func = [[TransitNativeFunction alloc] initWithRootContext:self.transit nativeId:@"someId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        NSString* data = arguments[0];

        // no callback? just return value
        if(arguments.count <= 1 || arguments[1] == NSNull.null)
            return data;
        
        TransitJSFunction *cb = arguments[1];
        // original API calls async, also this prevenst *very* deep recursion depths of up to 10,000!
        dispatch_async(dispatch_get_main_queue(), ^{
            [cb callWithArguments:@[data]];
        });
        
        return @0;
    }];
    [self.transit retainNativeProxy:func];
    
    // fake forge API to make same benchmark work
    [self.transit eval:@"window.forge = {internal:{ping:@}}" arguments:@[func]];
}

@end

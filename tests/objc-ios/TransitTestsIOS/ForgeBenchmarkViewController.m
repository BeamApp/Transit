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
    
    TransitNativeFunction *asyncFunc = (TransitNativeFunction*)[self.transit asyncFunctionWithBlock:^(TransitProxy *thisArg, NSArray *arguments) {
        NSString* data = arguments[0];
        TransitFunction *cb = arguments[1];
        
        // you could also use [cb callAsyncWithArg:data];
        // but since you don't need the result this *async* call is faster
        [cb callAsyncWithArg:data];
    }];
    
    TransitNativeFunction *blockingFunc = (TransitNativeFunction*)[self.transit functionWithBlock:^id(TransitProxy *thisArg, NSArray *arguments) {
        NSString* data = arguments[0];
        return data;
    }];

    // avoid unneeded passing of this == window.forge.internal object for each call on window.forge.internal.ping(...)
    asyncFunc.noThis = YES;
    blockingFunc.noThis = YES;

    [self.transit eval:@"window.forge = {internal:{ping: @, pingBlocked: @}}" val:asyncFunc val:blockingFunc];
}

@end

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
    
    TransitFunction *asyncFunc = [self.transit asyncFunctionWithBlock:^(TransitProxy *thisArg, NSArray *arguments) {
        NSString* data = arguments[0];
        TransitFunction *cb = arguments[1];
        
        // you could also use [cb callAsyncWithArg:data];
        // but since you don't need the result this *async* call is faster
        [cb callAsyncWithArg:data];
    }];
    
    TransitFunction *blockingFunc = [self.transit functionWithBlock:^id(TransitProxy *thisArg, NSArray *arguments) {
        NSString* data = arguments[0];
        return data;
    }];
    
    // fake forge API to make same benchmark work
    // but: ensure thisArg is always null to avoid unneeded serialization and get better performance, hence the ugly .apply()-statements ;)
    // TODO: 
    [self.transit eval:@"window.forge = "
     "{internal:{"
        "ping: function(){return @.apply(null, arguments)},"
        "pingBlocked: function(){return @.apply(null, arguments)},"
     "}}" arguments:@[asyncFunc, blockingFunc]];
}

@end

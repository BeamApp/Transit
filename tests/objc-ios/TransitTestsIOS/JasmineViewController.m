//
//  JasmineViewController.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 10.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "JasmineViewController.h"
#import "Transit.h"

@interface JasmineViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) TransitContext *transit;

@end

@implementation JasmineViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.title = @"Jasmine Tests";
    }
    return self;
}

-(void)viewDidLoad{
    self.transit = [[TransitUIWebViewContext alloc] initWithUIWebView:self.webView];

    NSURL *url = [NSBundle.mainBundle URLForResource:@"SpecRunner" withExtension:@"html" subdirectory:@"jasmine"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];


    [super viewDidLoad];
}


@end

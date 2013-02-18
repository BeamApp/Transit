//
//  XTypeViewController.h
//  TransitExampleIOS
//
//  Created by Heiko Behrens on 11.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailsViewController.h"

@interface XTypeViewController : DetailsViewController <UISplitViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (void)configureView;
@end

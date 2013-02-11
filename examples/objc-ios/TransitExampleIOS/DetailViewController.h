//
//  DetailViewController.h
//  TransitExampleIOS
//
//  Created by Heiko Behrens on 11.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end

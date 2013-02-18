//
//  MasterViewController.h
//  TransitExampleIOS
//
//  Created by Heiko Behrens on 11.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XTypeViewController;
@class DetailsViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailsViewController *detailViewController;

@end

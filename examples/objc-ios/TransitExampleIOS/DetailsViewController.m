//
// Created by behrens on 16.02.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "XTypeViewController.h"
#import "DetailsViewController.h"


@interface DetailsViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@interface DetailsViewController ()
@end

@implementation DetailsViewController {

}
- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (void)dealloc {
    NSLog(@"dealloc: %@", self);
}

@end
//
//  MasterViewController.m
//  TransitExampleIOS
//
//  Created by Heiko Behrens on 11.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "MasterViewController.h"

#import "XTypeViewController.h"
#import "ElizaViewController.h"
#import "DetailsViewController.h"
#import "ShareJSViewController.h"

@interface MasterViewController () {
}
@end

@implementation MasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Master", @"Master");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
    }
    
    int64_t delayInSeconds = 0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    });
    
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];

}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    if(indexPath.row == 0)
        cell.textLabel.text = @"X-Type";
    if(indexPath.row == 1)
        cell.textLabel.text = @"Eliza";
    if(indexPath.row == 2)
        cell.textLabel.text = @"ShareJS";

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.detailViewController = nil;
	    if (!self.detailViewController) {
            if(indexPath.row == 0)
	            self.detailViewController = [[XTypeViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil];
            if(indexPath.row == 1)
                self.detailViewController = [[ElizaViewController alloc] initWithNibName:@"ElizaViewController" bundle:nil];
            if(indexPath.row == 2)
                self.detailViewController = [[ShareJSViewController alloc] initWithNibName:@"ShareJSViewController" bundle:nil];
	    }
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
    }
}

@end

//
//  ViewController.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

// 
// Images used in this example by Petr Kratochvil released into public domain
// http://www.publicdomainpictures.net/view-image.php?image=9806
// http://www.publicdomainpictures.net/view-image.php?image=1358
//

#import "ViewController.h"
#import "SGBubbleTableView.h"
#import "SGBubbleTableViewDataSource.h"
#import "SGBubbleData.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet SGBubbleTableView *bubbleTable;
@property (nonatomic, weak) IBOutlet UIView *textInputView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, strong) NSMutableArray *bubbleData;

- (void)scrollToLastBubbleAnimated:(BOOL)animated;
- (NSIndexPath *)indexPathForLastBubble;

@end

@implementation ViewController

- (NSArray *)staticBubbleData
{
    SGBubbleData *heyBubble = [SGBubbleData dataWithText:@"Hey, halloween is soon"
                                                    date:[NSDate date]
                                               direction:SGBubbleDirectionLeft];

    NSString *replyBubbleText = @"Wow.. Really cool picture out there. iPhone 5 has really nice camera, yeah?";
    SGBubbleData *replyBubble = [SGBubbleData dataWithText:replyBubbleText
                                                      date:[NSDate date]
                                                 direction:SGBubbleDirectionRight];
    replyBubble.avatarImage = nil;
    
    return @[heyBubble, replyBubble];
}

- (void)viewDidLoad
{
    [[SGBubbleTableView appearance] setBackgroundColor:[UIColor lightGrayColor]];

    [super viewDidLoad];
    self.title = @"Eliza";

    self.bubbleData = [[self staticBubbleData] mutableCopy];

    self.bubbleTable.bubbleDataSource = self;
    self.bubbleTable.snapInterval = 120;
    self.bubbleTable.showAvatars = NO;
    [self.bubbleTable showTypingBubbleWithDirection:SGBubbleDirectionLeft];

    [self.bubbleTable reloadData];
    
    // Keyboard events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableViewDelegate implementation

#pragma mark - SGBubbleTableViewDataSource implementation

- (NSInteger)numberOfRowsForBubbleTableView:(SGBubbleTableView *)tableView
{
    return [self.bubbleData count];
}

- (SGBubbleData *)bubbleTableView:(SGBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return self.bubbleData[row];
}

#pragma mark - UIScrollView implementation

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.bubbleTable)
    {
        [self.textInputView endEditing:YES];
    }
}

#pragma mark - Keyboard events

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger animationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSInteger options = UIViewAnimationOptionBeginFromCurrentState | animationCurve;

    // TODO: Need to translate the bounds to account for rotation (correct?)
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        CGRect frame = self.textInputView.frame;
        frame.origin.y -= keyboardHeight;
        self.textInputView.frame = frame;

        frame = self.bubbleTable.frame;
        // TODO: keep the bottom of the visible area of the bubble table in view as the keyboard slides up
        // One solution is to leave the origin unchanged and animate the bubble table height
        // while scrolling in sync.
        // Another option is to animate the origin (subtract). Then, change the origin (add),
        // height (subtract) and scroll position (add) with no animation in the completion block
        // Yet another option is to fix UIBubbleTable to pass along scroll-related messages
        // and then adjust origin.y here and resignFirstResponder as soon as bubbleTable begins scrolling.
        // Finally, one more option: flip the table so that the visible bottom is actually the top
        // in this scenario, we would be able to animate the height and it would shrink upward
        //   https://github.com/StephenAsherson/FlippedTableView
        frame.size.height -= keyboardHeight;
//        frame.origin.y -= keyboardHeight;
        self.bubbleTable.frame = frame;
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger animationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSInteger options = UIViewAnimationOptionBeginFromCurrentState | animationCurve;

    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        CGRect frame = self.textInputView.frame;
        frame.origin.y += keyboardHeight;
        self.textInputView.frame = frame;
        
        frame = self.bubbleTable.frame;
        frame.size.height += keyboardHeight;
//        frame.origin.y += keyboardHeight;
        self.bubbleTable.frame = frame;
    } completion:^(BOOL finished) {
        [self scrollToLastBubbleAnimated:YES];
    }];
}

#pragma mark - Actions

- (IBAction)sayPressed:(id)sender
{
    [self.bubbleTable hideTypingBubble];

    SGBubbleData *sayBubble = [SGBubbleData dataWithText:self.textField.text date:[NSDate dateWithTimeIntervalSinceNow:0] direction:SGBubbleDirectionRight];
    [self.bubbleData addObject:sayBubble];
    [self.bubbleTable reloadData];

    self.textField.text = @"";
    [self scrollToLastBubbleAnimated:YES];
    if(sender) {
        [self.textField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sayPressed:nil];
    
    return NO;
}

#pragma mark Helpers

- (void)scrollToLastBubbleAnimated:(BOOL)animated
{
    [self.bubbleTable scrollToRowAtIndexPath:[self indexPathForLastBubble]
                            atScrollPosition:UITableViewScrollPositionBottom
                                    animated:animated];
}

-(NSIndexPath *)indexPathForLastBubble
{
    NSInteger finalSection = [self.bubbleTable numberOfSections] - 1;
    NSInteger finalRow = [self.bubbleTable numberOfRowsInSection:finalSection] - 1;
    return [NSIndexPath indexPathForRow:finalRow inSection:finalSection];
}

@end

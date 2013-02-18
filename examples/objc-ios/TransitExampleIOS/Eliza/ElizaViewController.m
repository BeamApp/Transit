//
//  ElizaViewController.m
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

#import "DetailsViewController.h"
#import "ElizaViewController.h"
#import "SGBubbleTableView.h"
#import "SGBubbleTableViewDataSource.h"
#import "SGBubbleData.h"
#import "Transit.h"

@interface ElizaViewController ()

@property (nonatomic, weak) IBOutlet SGBubbleTableView *bubbleTable;
@property (nonatomic, weak) IBOutlet UIView *textInputView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, strong) NSMutableArray *bubbleData;

- (void)scrollToLastBubbleAnimated:(BOOL)animated;
- (NSIndexPath *)indexPathForLastBubble;

@end

@implementation ElizaViewController {
    TransitContext *transit;
    id elizaBot;
}

- (NSArray *)staticBubbleData
{
    SGBubbleData *heyBubble = [SGBubbleData dataWithText:@"Hey, halloween is soon"
                                                    date:[NSDate date]
                                               direction:SGBubbleDirectionLeft];

    NSString *replyBubbleText = @"Wow.. Really cool picture out there. iPhone 5 has really nice camera, yeah?";
    SGBubbleData *replyBubble = [SGBubbleData dataWithText:replyBubbleText
                                                      date:[NSDate date]
                                                 direction:SGBubbleDirectionRight];

    return @[heyBubble, replyBubble];
}

- (void)viewDidLoad
{
    [[SGBubbleTableView appearance] setBackgroundColor:[UIColor lightGrayColor]];

    [super viewDidLoad];
    self.title = @"Eliza";

    self.bubbleData = [@[] mutableCopy];

    self.bubbleTable.bubbleDataSource = self;
    self.bubbleTable.snapInterval = 120;
    self.bubbleTable.showAvatars = NO;

    // Keyboard events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self wireTransit];
}

- (void)wireTransit {
    transit = [TransitUIWebViewContext contextWithUIWebView:UIWebView.new];

    NSString* path1 = [NSBundle.mainBundle pathForResource:@"elizadata" ofType:@"js"];
    NSString* path2 = [NSBundle.mainBundle pathForResource:@"elizabot" ofType:@"js"];

    NSString *js1 = [NSString stringWithContentsOfFile:path1 encoding:NSUTF8StringEncoding error:nil];
    [transit eval:@"(function(){@\n"
                  "window.elizaInitials=elizaInitials;window.elizaFinals=elizaFinals;window.elizaQuits=elizaQuits;window.elizaPres=elizaPres;window.elizaPosts=elizaPosts;window.elizaSynons=elizaSynons;window.elizaKeywords=elizaKeywords;window.elizaPostTransforms=elizaPostTransforms;"
              "\n})()" val:js1.stringAsJSExpression];


    NSString *js2 = [NSString stringWithContentsOfFile:path2 encoding:NSUTF8StringEncoding error:nil];
    elizaBot = [transit eval:@"(function(){@\n"
            "window.ElizaBot=ElizaBot;"
            "return window.elizaBot=new ElizaBot();"
            "\n})()" val:js2.stringAsJSExpression];

    NSLog(@"bot: %@", elizaBot);

    id initial = [transit eval:@"@.getInitial()" val:elizaBot];
    [self pushElizaAnswer: initial];
}

- (void)pushElizaAnswer:(NSString *)answer {
    [self.bubbleTable showTypingBubbleWithDirection:SGBubbleDirectionLeft];

    [self.bubbleTable reloadData];
    [self scrollToLastBubbleAnimated:YES];

    SGBubbleData *bubble = [SGBubbleData dataWithText:answer
                                                 date:[NSDate date]
                                            direction:SGBubbleDirectionLeft];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.bubbleData addObject:bubble];
        [self.bubbleTable hideTypingBubble];
        [self.bubbleTable reloadData];
        [self scrollToLastBubbleAnimated:YES];
    });

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
    } completion:^(BOOL finished) {
        [self scrollToLastBubbleAnimated:YES];
    }];
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

    NSString* answer = [transit eval:@"@.transform(@)" val:elizaBot val:self.textField.text];
    self.textField.text = @"";

    [self pushElizaAnswer:answer];

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

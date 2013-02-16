//
//  UIBubbleTableView.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <UIKit/UIKit.h>
#import "SGBubbleTableViewAdapter.h"
#import "SGBubbleTableViewDataSource.h"
#import "SGBubbleTableViewContentCell.h"


@interface SGBubbleTableView : UITableView

@property (nonatomic, strong) id<SGBubbleTableViewAdapterProtocol> adapter;

#pragma mark Compiler hints

@property (nonatomic, assign) id<SGBubbleTableViewDataSource> bubbleDataSource;

@property (nonatomic) NSTimeInterval snapInterval;
@property (nonatomic) BOOL showAvatars;

- (void)hideTypingBubble;
- (void)showTypingBubbleWithDirection:(SGBubbleDirection)direction;

#pragma mark UIAppearanceContainerProtocol hooks

@property (nonatomic, strong) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UITableViewCellSeparatorStyle separatorStyle UI_APPEARANCE_SELECTOR;
//@property (nonatomic) BOOL showsVerticalScrollIndicator UI_APPEARANCE_SELECTOR;
//@property (nonatomic) BOOL showsHorizontalScrollIndicator UI_APPEARANCE_SELECTOR;

@end

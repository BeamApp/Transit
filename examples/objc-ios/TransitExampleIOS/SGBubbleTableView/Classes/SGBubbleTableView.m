//
//  UIBubbleTableView.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "SGBubbleTableView.h"
#import "SGBubbleData.h"
#import "SGBubbleTableViewHeaderCell.h"
#import "SGBubbleTableViewTypingCell.h"

@interface SGBubbleTableView ()

@property (nonatomic, retain) NSMutableArray *bubbleSection;

@end

@implementation SGBubbleTableView

#pragma mark - Initializators

- (void)initializator
{
    self.adapter = [self createAdapter];
    // UITableView properties
    assert(self.style == UITableViewStylePlain);
}

- (id)init
{
    self = [super init];
    if (self) [self initializator];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) [self initializator];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) [self initializator];
    return self;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) [self initializator];
    return self;
}

#pragma mark - UIAppearance implementations

@dynamic backgroundColor;
@dynamic separatorStyle;
//@dynamic showsVerticalScrollIndicator;
//@dynamic showsHorizontalScrollIndicator;

+ (void)load
{
    [[self appearance] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    //    [[self appearance] setBackgroundColor:[UIColor clearColor]];
    //    [[self appearance] setShowsHorizontalScrollIndicator:NO];
    //    [[self appearance] setShowsVerticalScrollIndicator:NO];
}

- (UITableViewCellSeparatorStyle)separatorStyle
{
    return [super separatorStyle];
}

- (void)setSeparatorStyle:(UITableViewCellSeparatorStyle)separatorStyle
{
    [super setSeparatorStyle:separatorStyle];
}

- (UIColor *)backgroundColor
{
    return [super backgroundColor];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
}

//- (BOOL)showsVerticalScrollIndicator
//{
//    return [super showsHorizontalScrollIndicator];
//}

//- (void)setShowsVerticalScrollIndicator:(BOOL)showsHorizontalScrollIndicator
//{
//    [super setShowsHorizontalScrollIndicator:showsHorizontalScrollIndicator];
//}

//- (BOOL)showsHorizontalScrollIndicator
//{
//    return [super showsHorizontalScrollIndicator];
//}

//- (void)setShowsHorizontalScrollIndicator:(BOOL)showsHorizontalScrollIndicator
//{
//    [super setShowsHorizontalScrollIndicator:showsHorizontalScrollIndicator];
//}

#pragma mark - Override

@dynamic bubbleDataSource;
@dynamic snapInterval;
@dynamic showAvatars;

- (void)reloadData
{
    [self.adapter willReloadData];
    [super reloadData];
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    [self.adapter setDelegate:delegate];
}

- (void)setAdapter:(id<SGBubbleTableViewAdapterProtocol>)adapter
{
    _adapter = adapter;
    [super setDelegate:adapter];
    self.dataSource = adapter;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ((aSelector == @selector(bubbleDataSource)) || (aSelector == @selector(setBubbleDataSource:)))
    {
        return self.adapter;
    }
    else if ((aSelector == @selector(snapInterval)) || (aSelector == @selector(setSnapInterval:)))
    {
        return self.adapter;
    }
    else if ((aSelector == @selector(showAvatars)) || (aSelector == @selector(setShowAvatars:)))
    {
        return self.adapter;
    }
    else if ((aSelector == @selector(hideTypingBubble)) || (aSelector == @selector(showTypingBubbleWithDirection:)))
    {
        return self.adapter;
    }
    else
    {
        return [super forwardingTargetForSelector:aSelector];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ((aSelector == @selector(bubbleDataSource)) || (aSelector == @selector(setBubbleDataSource:)))
    {
        return YES;
    }
    else if ((aSelector == @selector(snapInterval)) || (aSelector == @selector(setSnapInterval:)))
    {
        return YES;
    }
    else if ((aSelector == @selector(showAvatars)) || (aSelector == @selector(setShowAvatars:)))
    {
        return YES;
    }
    else if ((aSelector == @selector(hideTypingBubble)) ||(aSelector == @selector(showTypingBubbleWithDirection:)))
    {
        return YES;
    }
    else
    {
        return [super respondsToSelector:aSelector];
    }
}

#pragma mark - Helpers

- (id<SGBubbleTableViewAdapterProtocol>)createAdapter
{
    return [[SGBubbleTableViewAdapter alloc] initWithBubbleTableView:self];
}

@end

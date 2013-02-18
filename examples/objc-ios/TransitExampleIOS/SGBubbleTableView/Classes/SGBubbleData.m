//
//  NSBubbleData.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "SGBubbleData.h"
#import <QuartzCore/QuartzCore.h>

@implementation SGBubbleData

#pragma mark - Properties

#pragma mark - Lifecycle

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_date release];
	_date = nil;
    [_view release];
    _view = nil;
    
    self.avatarImage = nil;

    [super dealloc];
}
#endif

#pragma mark - Text bubble

const UIEdgeInsets kSGBubbleDataTextInsetsRight = {5, 10, 11, 17};
const UIEdgeInsets kSGBubbleDataTextInsetsLeft = {5, 15, 11, 10};
const UIEdgeInsets kSGBubbleDataImageInsetsRight = {11, 13, 16, 22};
const UIEdgeInsets kSGBubbleDataImageInsetsLeft = {11, 18, 16, 14};

const NSInteger kMaxContentWidth = 200;
const NSInteger kMaxContentHeight = 9999;

+ (id)dataWithText:(NSString *)text date:(NSDate *)date direction:(SGBubbleDirection)direction
{
#if !__has_feature(objc_arc)
    return [[[SGBubbleData alloc] initWithText:text date:date direction:direction] autorelease];
#else
    return [[SGBubbleData alloc] initWithText:text date:date direction:direction];
#endif    
}

- (id)initWithText:(NSString *)text date:(NSDate *)date direction:(SGBubbleDirection)direction
{
    if (!text) text = @"";
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = [text sizeWithFont:font
                   constrainedToSize:CGSizeMake(kMaxContentWidth, kMaxContentHeight)
                       lineBreakMode:UILineBreakModeWordWrap];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = text;
    label.font = font;
    label.backgroundColor = [UIColor clearColor];
    
#if !__has_feature(objc_arc)
    [label autorelease];
#endif
    
    UIEdgeInsets insets = (direction == SGBubbleDirectionLeft ? kSGBubbleDataTextInsetsLeft : kSGBubbleDataTextInsetsRight);
    return [self initWithView:label date:date direction:direction insets:insets];
}

#pragma mark - Image bubble

+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date direction:(SGBubbleDirection)direction
{
#if !__has_feature(objc_arc)
    return [[[SGBubbleData alloc] initWithImage:image date:date direction:direction] autorelease];
#else
    return [[SGBubbleData alloc] initWithImage:image date:date direction:direction];
#endif    
}

- (id)initWithImage:(UIImage *)image date:(NSDate *)date direction:(SGBubbleDirection)direction
{
    CGSize size = image.size;
    if (size.width > kMaxContentWidth)
    {
        size.height /= (size.width / kMaxContentWidth);
        size.width = kMaxContentWidth;
    }

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    imageView.image = image;
    imageView.layer.cornerRadius = 5.0;
    imageView.layer.masksToBounds = YES;

#if !__has_feature(objc_arc)
    [imageView autorelease];
#endif
    
    UIEdgeInsets insets = (direction == SGBubbleDirectionRight ? kSGBubbleDataImageInsetsRight : kSGBubbleDataImageInsetsLeft);
    return [self initWithView:imageView date:date direction:direction insets:insets];       
}

#pragma mark - Custom view bubble

+ (id)dataWithView:(UIView *)view date:(NSDate *)date direction:(SGBubbleDirection)direction insets:(UIEdgeInsets)insets
{
#if !__has_feature(objc_arc)
    return [[[SGBubbleData alloc] initWithView:view date:date direction:direction insets:insets] autorelease];
#else
    return [[SGBubbleData alloc] initWithView:view date:date direction:direction insets:insets];
#endif    
}

- (id)initWithView:(UIView *)view date:(NSDate *)date direction:(SGBubbleDirection)direction insets:(UIEdgeInsets)insets  
{
    self = [super init];
    if (self)
    {
        _view = view;
        _date = date;
#if !__has_feature(objc_arc)
        [view retain];
        [date retain];
#endif
        _direction = direction;
        _insets = insets;
    }
    return self;
}

- (CGSize)contentSize
{
    return self.view.frame.size;
}

- (CGSize)totalSize
{
    CGSize contentSize = [self contentSize];
    UIEdgeInsets insets = self.insets;
    return CGSizeMake(contentSize.width + insets.left + insets.right,
                      contentSize.height + insets.top + insets.bottom);
}

@end

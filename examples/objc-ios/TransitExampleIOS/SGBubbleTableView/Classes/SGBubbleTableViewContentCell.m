//
//  UIBubbleTableViewCell.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <QuartzCore/QuartzCore.h>
#import "SGBubbleTableViewContentCell.h"
#import "SGBubbleData.h"

@interface SGBubbleTableViewContentCell ()

@property (nonatomic, retain) UIView *customView;
@property (nonatomic, retain) UIImageView *bubbleImageView;
@property (nonatomic, retain) UIImageView *avatarImageView;

- (UIImage *)bubbleImage;
- (CGRect)avatarImageViewFrame;
- (CGFloat)bubbleImageViewFrameX;
- (CGFloat)bubbleImageViewFrameY;
- (CGFloat)totalAvatarWidth;

- (void)setupInternalData;

@end

static CGFloat kSGBubbleTableViewContentCellAvatarWidth = 50;
static CGFloat kSGBubbleTableViewContentCellAvatarHorizontalSpace = 2;
static CGFloat kSGBubbleTableViewContentCellAvatarHeight = 50;

@implementation SGBubbleTableViewContentCell

+ (SGBubbleTableViewContentCell *)cellWithDirection:(SGBubbleDirection)direction avatar:(BOOL)showAvatar reuseIdentifier:(NSString *)reuseIdentifier
{
    Class cellFactory = nil;

    switch (direction) {
        case SGBubbleDirectionLeft:
            cellFactory = [SGBubbleTableViewContentCellLeft class];
            break;
        case SGBubbleDirectionRight:
            cellFactory = [SGBubbleTableViewContentCellRight class];
            break;

        default:
            break;
    }

    return [[cellFactory alloc] initWithAvatar:showAvatar reuseIdentifier:reuseIdentifier];
}

- (id)initWithAvatar:(BOOL)showAvatar reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];

    if (self)
    {
        _showAvatar = showAvatar;

        if (self.showAvatar)
        {
            self.avatarImageView = [[UIImageView alloc] initWithImage:[self defaultAvatarImage]];
#if !__has_feature(objc_arc)
            [self.avatarImageView autorelease];
#endif
            [self configureAvatarImageView];
            [self addSubview:self.avatarImageView];
        }
    }

    return self;
}

- (UIImage *)defaultAvatarImage
{
    return [UIImage imageNamed:@"missingAvatar.png"];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
	[self setupInternalData];
}

#if !__has_feature(objc_arc)
- (void) dealloc
{
    self.data = nil;
    self.customView = nil;
    self.bubbleImageView = nil;
    self.avatarImageView = nil;
    [super dealloc];
}
#endif

- (void)setDataInternal:(SGBubbleData *)value
{
	self.data = value;
	[self setupInternalData];
}

- (void) setupInternalData
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (!self.bubbleImageView)
    {
        self.bubbleImageView = [[UIImageView alloc] init];
#if !__has_feature(objc_arc)
        [self.bubbleImageView autorelease];
#endif
        [self addSubview:self.bubbleImageView];
    }

    if (self.showAvatar)
    {
        UIImage *avatarImage = self.data.avatarImage ?: [self defaultAvatarImage];
        self.avatarImageView.image = avatarImage;
        self.avatarImageView.frame = [self avatarImageViewFrame];
    }

    [self.customView removeFromSuperview];
    self.customView = self.data.view;
    CGSize customViewSize = [self.data contentSize];
    self.customView.frame = CGRectMake([self bubbleImageViewFrameX] + self.data.insets.left,
                                       [self bubbleImageViewFrameY] + self.data.insets.top,
                                       customViewSize.width,
                                       customViewSize.height);
    [self.contentView addSubview:self.customView];

    self.bubbleImageView.image = [self bubbleImage];
    CGSize bubbleContentViewSize = [self.data totalSize];
    self.bubbleImageView.frame = CGRectMake([self bubbleImageViewFrameX],
                                            [self bubbleImageViewFrameY],
                                            bubbleContentViewSize.width,
                                            bubbleContentViewSize.height);
}

- (CGFloat)avatarOffsetY
{
    return self.frame.size.height - kSGBubbleTableViewContentCellAvatarHeight;
}

- (void)configureAvatarImageView
{
    self.avatarImageView.layer.cornerRadius = 9.0;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.2].CGColor;
    self.avatarImageView.layer.borderWidth = 1.0;
}

- (CGFloat)totalAvatarWidth
{
    CGFloat x = 0;
    if (self.showAvatar)
    {
        x += kSGBubbleTableViewContentCellAvatarWidth;
        x += 2 * kSGBubbleTableViewContentCellAvatarHorizontalSpace;
    }
    return x;
}

- (CGFloat)bubbleImageViewFrameX
{
    return 0;
}

- (CGFloat)bubbleImageViewFrameY
{
    CGFloat y = 0;
    if (self.showAvatar)
    {
        CGFloat delta = self.frame.size.height - [self.data totalSize].height;
        if (delta > 0) y = delta;
    }
    
    return y;
}

- (UIImage *)bubbleImage
{
    return nil;
}

- (CGRect)avatarImageViewFrame
{
    return CGRectZero;
}

@end

@implementation SGBubbleTableViewContentCellLeft

- (UIImage *)bubbleImage
{
    return [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
}

- (CGFloat)bubbleImageViewFrameX
{
    return [self totalAvatarWidth];
}

- (CGRect)avatarImageViewFrame
{
    return CGRectMake(kSGBubbleTableViewContentCellAvatarHorizontalSpace,
                      self.frame.size.height - kSGBubbleTableViewContentCellAvatarHeight,
                      kSGBubbleTableViewContentCellAvatarWidth,
                      kSGBubbleTableViewContentCellAvatarHeight);
}

@end

@implementation SGBubbleTableViewContentCellRight

- (UIImage *)bubbleImage
{
    return [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
}

- (CGFloat)bubbleImageViewFrameX
{
    return self.frame.size.width - [self.data totalSize].width - [self totalAvatarWidth];
}

- (CGRect)avatarImageViewFrame
{
    return CGRectMake(self.frame.size.width - [self totalAvatarWidth],
                      self.frame.size.height - kSGBubbleTableViewContentCellAvatarHeight,
                      kSGBubbleTableViewContentCellAvatarWidth,
                      kSGBubbleTableViewContentCellAvatarHeight);
}

@end

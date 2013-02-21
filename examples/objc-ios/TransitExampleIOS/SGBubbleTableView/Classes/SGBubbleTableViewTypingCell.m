//
//  UIBubbleTypingTableCell.m
//  UIBubbleTableViewExample
//
//  Created by Александр Баринов on 10/7/12.
//  Copyright (c) 2012 Stex Group. All rights reserved.
//

#import "SGBubbleTableViewTypingCell.h"

static int const kSGBubbleTableViewTypingCellOffsetY = 4;
static int const kSGBubbleTableViewTypingCellWidth = 73;
static int const kSGBubbleTableViewTypingCellHeight = 31;

@interface SGBubbleTableViewTypingCell ()

@property (nonatomic, retain) UIImageView *typingImageView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (UIImageView *)typingImageViewWithImage:(UIImage *)typingImage;
- (CGFloat)bubbleOffsetXWithBubbleImage:(UIImage *)bubbleImage;
- (UIImage *)bubbleImage;

@end

@implementation SGBubbleTableViewTypingCell

@synthesize typingImageView = _typingImageView;
@synthesize showAvatar = _showAvatar;

+ (SGBubbleTableViewTypingCell *)cellWithDirection:(SGBubbleDirection)direction reuseIdentifier:(NSString *)reuseIdentifier
{
    Class cellFactory = nil;

    switch (direction) {
        case SGBubbleDirectionLeft:
            cellFactory = [SGBubbleTableViewTypingLeftCell class];
            break;
            
        case SGBubbleDirectionRight:
            cellFactory = [SGBubbleTableViewTypingRightCell class];
            break;
            
        default:
            break;
    }

    return [[cellFactory alloc] initWithReuseIdentifier:reuseIdentifier];
}

+ (CGFloat)height
{
    return 40.0;
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.typingImageView = [self typingImageViewWithImage:[self bubbleImage]];
        [self addSubview:self.typingImageView];

        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

- (UIImageView *)typingImageViewWithImage:(UIImage *)typingImage
{
    UIImageView *typingImageView = [[UIImageView alloc] initWithImage:typingImage];
    CGRect frame = typingImageView.frame;
    frame.origin.x = [self bubbleOffsetXWithBubbleImage:typingImage];
    frame.origin.y = kSGBubbleTableViewTypingCellOffsetY;
    typingImageView.frame = frame;

    return typingImageView;
}

- (CGFloat)bubbleOffsetXWithBubbleImage:(UIImage *)bubbleImage
{
    return 0;
}

- (UIImage *)bubbleImage
{
    return nil;
}

@end


@implementation SGBubbleTableViewTypingLeftCell

- (UIImage *)bubbleImage
{
    return [UIImage imageNamed:@"typingSomeone.png"];
}

@end


@implementation SGBubbleTableViewTypingRightCell

- (UIImage *)bubbleImage
{
    return [UIImage imageNamed:@"typingMine.png"];
}

- (CGFloat)bubbleOffsetXWithBubbleImage:(UIImage *)bubbleImage
{
    return self.frame.size.width - bubbleImage.size.width;
}

@end

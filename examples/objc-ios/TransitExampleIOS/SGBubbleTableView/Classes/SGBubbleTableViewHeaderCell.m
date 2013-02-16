//
//  UIBubbleHeaderTableViewCell.m
//  UIBubbleTableViewExample
//
//  Created by Александр Баринов on 10/7/12.
//  Copyright (c) 2012 Stex Group. All rights reserved.
//

#import "SGBubbleTableViewHeaderCell.h"

@interface SGBubbleTableViewHeaderCell ()

@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;

@end

@implementation SGBubbleTableViewHeaderCell

@synthesize label = _label;
@synthesize date = _date;

+ (CGFloat)height
{
    return 28.0;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.dateFormatter = [self createDateFormatter];
        self.label = [self createLabel];
        [self addSubview:self.label];
    }

    return self;
}

- (void)setDate:(NSDate *)value
{
    self.label.text = [self.dateFormatter stringFromDate:value];
}

- (NSDateFormatter *)createDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];

    return dateFormatter;
}

- (UILabel *)createLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [SGBubbleTableViewHeaderCell height])];
    label.font = [UIFont boldSystemFontOfSize:12];
    label.textAlignment = UITextAlignmentCenter;
    label.shadowOffset = CGSizeMake(0, 1);
    label.shadowColor = [UIColor whiteColor];
    label.textColor = [UIColor darkGrayColor];
    label.backgroundColor = [UIColor clearColor];

    return label;
}

@end

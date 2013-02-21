//
//  UIBubbleTypingTableCell.h
//  UIBubbleTableViewExample
//
//  Created by Александр Баринов on 10/7/12.
//  Copyright (c) 2012 Stex Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGBubbleTableView.h"


@interface SGBubbleTableViewTypingCell : UITableViewCell

+ (CGFloat)height;
+ (SGBubbleTableViewTypingCell *)cellWithDirection:(SGBubbleDirection)direction reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic) BOOL showAvatar;

@end

@interface SGBubbleTableViewTypingLeftCell : SGBubbleTableViewTypingCell
@end

@interface SGBubbleTableViewTypingRightCell : SGBubbleTableViewTypingCell
@end

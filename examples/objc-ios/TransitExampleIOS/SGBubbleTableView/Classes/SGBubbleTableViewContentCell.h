//
//  UIBubbleTableViewCell.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <UIKit/UIKit.h>
#import "SGBubbleData.h"

@interface SGBubbleTableViewContentCell : UITableViewCell

@property (nonatomic, strong) SGBubbleData *data;
@property (nonatomic, readonly) BOOL showAvatar;

+ (SGBubbleTableViewContentCell *)cellWithDirection:(SGBubbleDirection)direction avatar:(BOOL)showAvatar reuseIdentifier:(NSString *)reuseIdentifier;

- (id)initWithAvatar:(BOOL)showAvatar reuseIdentifier:(NSString *)reuseIdentifier;

@end

@interface SGBubbleTableViewContentCellLeft : SGBubbleTableViewContentCell

@end

@interface SGBubbleTableViewContentCellRight : SGBubbleTableViewContentCell

@end

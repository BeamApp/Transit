//
//  NSBubbleData.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <Foundation/Foundation.h>

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

typedef NS_ENUM(NSInteger, SGBubbleDirection)
{
    SGBubbleDirectionRight,
    SGBubbleDirectionLeft
};


@interface SGBubbleData : NSObject

@property (readonly, nonatomic, strong) NSDate *date;
@property (readonly, nonatomic) SGBubbleDirection direction;
@property (readonly, nonatomic, strong) UIView *view;
@property (readonly, nonatomic) UIEdgeInsets insets;
@property (nonatomic, strong) UIImage *avatarImage;

+ (id)dataWithText:(NSString *)text date:(NSDate *)date direction:(SGBubbleDirection)direction;
+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date direction:(SGBubbleDirection)direction;
+ (id)dataWithView:(UIView *)view date:(NSDate *)date direction:(SGBubbleDirection)direction insets:(UIEdgeInsets)insets;

- (id)initWithText:(NSString *)text date:(NSDate *)date direction:(SGBubbleDirection)direction;
- (id)initWithImage:(UIImage *)image date:(NSDate *)date direction:(SGBubbleDirection)direction;
- (id)initWithView:(UIView *)view date:(NSDate *)date direction:(SGBubbleDirection)direction insets:(UIEdgeInsets)insets;

- (CGSize)contentSize;
- (CGSize)totalSize;

@end

//
//  SGBubbleTableViewAdapterProtocol.h
//  UIBubbleTableViewExample
//
//  Created by Emmanuel Gomez on 1/9/13.
//  Copyright (c) 2013 Stex Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGBubbleTableViewDataSource.h"

@protocol SGBubbleTableViewAdapterProtocol <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id<UITableViewDelegate> delegate;
@property (nonatomic, weak) id<SGBubbleTableViewDataSource> bubbleDataSource;

@property (nonatomic, assign) NSTimeInterval snapInterval;
@property (nonatomic, assign) BOOL showAvatars;

@required
- (void)willReloadData;

@optional
- (void)didReloadData;

@end

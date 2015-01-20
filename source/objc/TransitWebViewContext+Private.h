//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#if TRANSIT_OS_MAC

#import "TransitWebViewContext.h"

@interface TransitWebViewContext (Private)

@property (nonatomic) BOOL shouldWaitForTransitLoaded;
@property (weak, nonatomic) id originalFrameLoadDelegate;

@end

#endif

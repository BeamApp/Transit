//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitContext.h"

/// Abstract base-class for TransitUIWebViewContext and TransitWebViewContext
@interface TransitAbstractWebViewContext : TransitContext
- (void)injectCodeToWebView;
@end

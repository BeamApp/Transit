//
//  TransitEvaluator.h
//  TransitTestsIOS
//
//  Created by Marcel Jackwerth on 16/01/15.
//  Copyright (c) 2015 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TransitCallScope;

@protocol TransitEvaluator <NSObject>

- (id)_eval:(NSString *)jsExpression jsThisArg:(NSString *)jsAdjustedThisArg collectedProxiesOnScope:(NSOrderedSet *)proxiesOnScope returnJSResult:(BOOL)returnJSResult onGlobalScope:(BOOL)globalScope useAndRestoreCallScope:(TransitCallScope *)callScope;
- (id)_eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)arguments returnJSResult:(BOOL)returnJSResult useAndRestoreCallScope:(TransitCallScope *)callScope;

@end


//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface TransitAbstractWebViewContextTests : SenTestCase

- (void)testResultTypes;

- (void)testInjectsCodeOnReloadOfURLLoad;

- (void)testProxifyOfGlobalObject;

- (NSString *)htmlStringForEmptyPage;

- (void)testSimpleCallFromWebView;

- (void)testRecursiveCallBetweenWebViewAndNative;

- (void)testConvenientSettingOfGlobalFunc;

- (void)testPerformance;

- (void)testAsyncInvocationQueue;
@end

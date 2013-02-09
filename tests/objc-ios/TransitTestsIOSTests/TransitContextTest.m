//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Transit.h"
#import "Transit+Private.h"
#import "OCMock.h"


@interface FakeNativeProxyForTest : TransitProxy

@end

@implementation FakeNativeProxyForTest

-(void)dispose {
    if(self.rootContext && self.proxyId) {
        [self.rootContext releaseNativeProxy:self];
    }
    [self clearRootContextAndProxyId];
}
@end

@interface TransitContextTests : SenTestCase

@end

@implementation TransitContextTests {
    NSUInteger _transitContextLivingInstanceCountBefore;
}

-(void)setUp {
    [super setUp];
    _transitContextLivingInstanceCountBefore = _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT;
}

-(void)tearDown {
    STAssertEquals(_transitContextLivingInstanceCountBefore, _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT, @"no garbage context created");
    [super tearDown];
}

-(void)testJsRepresentationForProxy {
    TransitContext *context = [TransitContext new];
    NSString* actual = [context jsRepresentationForProxyWithId:@"someId"];
    STAssertEqualObjects(@"transit.retained[\"someId\"]", actual, @"proxy representation");
}

-(TransitProxy*)stubWithContext:(TransitContext*)context proxyId:(NSString*)proxyId {
    id proxy = [OCMockObject mockForClass:TransitProxy.class];
    [[[proxy stub] andReturn:context] rootContext];
    [[[proxy stub] andReturn:proxyId] proxyId];
    return proxy;
}

-(void)testSingleNativeRetain {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context retainNativeProxy:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{@"someId":proxy}), @"correctly retained");
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(void)testMultipleNativeRetains {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *p1 = [self stubWithContext:context proxyId:@"id1"];
        TransitProxy *p2 = [self stubWithContext:context proxyId:@"id2"];
        [context retainNativeProxy:p1];
        [context retainNativeProxy:p2];
        STAssertEqualObjects(context.retainedNativeProxies, (@{@"id1":p1, @"id2":p2}), @"retains both");
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(void)testMutipleNativeRetainsForSameObjectWithoutEffect {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        [context retainNativeProxy:proxy];
        STAssertEquals((NSUInteger)1, context.retainedNativeProxies.count, @"retains one object");
        [context retainNativeProxy:proxy];
        STAssertEquals((NSUInteger)1, context.retainedNativeProxies.count, @"still retains object");
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(void)testNativeRetainRelease {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context retainNativeProxy:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{@"someId":proxy}), @"correctly retained");
        [context releaseNativeProxy:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained anymore");
    }
}

-(void)testCannotReleaseNonRetained {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy =  [self stubWithContext:context proxyId:@"someId"];
        
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context releaseNativeProxy:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"still, nothing retained");
    }
}

-(void)testDisposesNativeProxiesOnDispose {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        [[(OCMockObject*)proxy expect] dispose];
        [context retainNativeProxy:proxy];
        [context dispose];
        [(OCMockObject*)proxy verify];
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(TransitProxy*)createAndReleaseContextButReturnNativeProxy {
    TransitProxy *proxy;

    @autoreleasepool {
        TransitContext* context = TransitContext.new;
        STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)context), @"single ref");
        proxy = [[FakeNativeProxyForTest alloc]initWithRootContext:context proxyId:@"someId"];
        STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)context), @"still, single ref to context");
        STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)proxy), @"var keeps ref to proxy");
        
        [context retainNativeProxy:proxy];
    }
    STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)proxy), @"var keeps ref to proxy");
    
    return proxy;
}

-(void)testNoRetainCyclesAndDisposesNativeProxies {
    __weak TransitProxy* proxy;
    @autoreleasepool {
        proxy = [self createAndReleaseContextButReturnNativeProxy];
        
        STAssertTrue(proxy.disposed, @"proxy has been disposed");
        STAssertNil(proxy.rootContext, @"hence, does not keep reference to context anymore");
    }
    STAssertNil(proxy, @"proxy is free");
}



@end

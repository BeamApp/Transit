#import "CCWeakMockProxy.h"
#import <OCMock/OCMock.h>


#pragma mark Implementation
@implementation CCWeakMockProxy

#pragma mark Properties
@synthesize mock;

#pragma mark Memory Management
- (id)initWithMock:(id)mockObj {
    if (self = [super init]) {
        self.mock = mockObj;
    }
    return self;
}

#pragma mark NSObject
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.mock;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.mock respondsToSelector:aSelector];
}

#pragma mark Public Methods
+ (id)mockForClass:(Class)aClass {
    return [[CCWeakMockProxy alloc] initWithMock:[OCMockObject mockForClass:aClass]];
}

+ (id)mockForProtocol:(Protocol *)aProtocol {
    return [[CCWeakMockProxy alloc] initWithMock:[OCMockObject mockForProtocol:aProtocol]];
}

+ (id)niceMockForClass:(Class)aClass {
    return [[CCWeakMockProxy alloc] initWithMock:[OCMockObject niceMockForClass:aClass]];
}

+ (id)niceMockForProtocol:(Protocol *)aProtocol {
    return [[CCWeakMockProxy alloc] initWithMock:[OCMockObject niceMockForProtocol:aProtocol]];
}

+ (id)observerMock {
    return [[CCWeakMockProxy alloc] initWithMock:[OCMockObject observerMock]];
}

+ (id)partialMockForObject:(NSObject *)anObject {
    return [[CCWeakMockProxy alloc] initWithMock:[OCMockObject partialMockForObject:anObject]];
}

@end
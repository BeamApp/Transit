#import <Foundation/Foundation.h>

/**
 * This class is a hack around the fact that ARC weak references are immediately nil'd if the referent is an NSProxy
 * See: http://stackoverflow.com/questions/9104544/how-can-i-get-ocmock-under-arc-to-stop-nilling-an-nsproxy-subclass-set-using-a-w
 */
@interface CCWeakMockProxy : NSObject

@property (strong, nonatomic) id mock;

- (id)initWithMock:(id)mockObj;

+ (id)mockForClass:(Class)aClass;
+ (id)mockForProtocol:(Protocol *)aProtocol;
+ (id)niceMockForClass:(Class)aClass;
+ (id)niceMockForProtocol:(Protocol *)aProtocol;
+ (id)observerMock;
+ (id)partialMockForObject:(NSObject *)anObject;

@end
//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#define TRANSIT_OS_MAC (TARGET_OS_MAC && !(TARGET_OS_IPHONE))
#define TRANSIT_OS_IOS (TARGET_OS_IPHONE)

@class TransitFunction;
@class TransitNativeFunctionCallScope;

typedef id (^TransitGenericFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef void (^TransitGenericVoidFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef id (^TransitGenericReplaceFunctionBlock)(TransitFunction* original, TransitNativeFunctionCallScope *callScope);

extern NSUInteger _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT;
extern NSUInteger _TRANSIT_DRAIN_JS_PROXIES_THRESHOLD;
extern CGFloat _TRANSIT_ASYNC_CALL_DELAY;
extern NSString* _TRANSIT_MARKER_PREFIX_JS_FUNCTION_;
extern NSString* _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_;
extern NSString* _TRANSIT_MARKER_GLOBAL_OBJECT;

extern NSString* _TRANSIT_MARKER_PREFIX_NATIVE_FUNCTION;
extern NSUInteger _TRANSIT_MARKER_PREFIX_MIN_LEN;
extern NSString* _TRANSIT_JS_RUNTIME_CODE;

BOOL transit_iOS_6_OrLater();
BOOL transit_iOS_7_OrLater();
BOOL transit_iOS_8_OrLater();
BOOL transit_OSX_10_8_OrLater();
BOOL transit_OSX_10_9_OrLater();

BOOL transit_specificBlocksSupported();

NSString* transit_stringAsJSExpression(NSString* string);
BOOL transit_isJSExpression(NSString* string);

id TransitNilSafe(id valueOrNil);

NSError *transit_errorWithCodeFromException(NSUInteger code, NSException* exception);

extern NSString* _TRANSIT_SCHEME;



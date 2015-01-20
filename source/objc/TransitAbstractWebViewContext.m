//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitAbstractWebViewContext.h"
#import "SBJsonParser.h"
#import "TransitCallScope.h"
#import "TransitEvalCallScope.h"
#import "TransitAbstractWebViewContext+Private.h"
#import "TransitContext+Private.h"
#import "TransitCore.h"
#import "TransitProxy.h"
#import "TransitProxy+Private.h"
#import "TransitEvalCallScope+Private.h"

TransitWebViewContextRequestHandler _TRANSIT_DEFAULT_UIWEBVIEW_REQUEST_HANDLER = ^(TransitAbstractWebViewContext* ctx,NSURLRequest* request) {
    [ctx doInvokeNative];
};

@implementation TransitAbstractWebViewContext {
    SBJsonParser *_parser;
    BOOL _codeInjected;
    BOOL _proxifyEval;
    TransitWebViewContextRequestHandler _handleRequestBlock;
    NSString* _lastEvaluatedJSCode;
}

- (id)init {
    self = [super init];
    if(self) {
        _proxifyEval = YES;
        _parser = SBJsonParser.new;
        _handleRequestBlock = _TRANSIT_DEFAULT_UIWEBVIEW_REQUEST_HANDLER;
    }
    return self;
}

-(BOOL)codeInjected {
    return _codeInjected;
}

-(NSString*)_eval:(NSString*)js returnJSONResult:(BOOL)returnJSONResult{
    if(returnJSONResult) {
        _lastEvaluatedJSCode = [NSString stringWithFormat: @"JSON.stringify(%@)", js];
        return [self _stringByEvaluatingJavaScriptFromString: _lastEvaluatedJSCode];
    } else {
        //        NSLog(@"eval: %@", js);
        return [self _stringByEvaluatingJavaScriptFromString:js];
    }
}

- (NSString *)_stringByEvaluatingJavaScriptFromString:(NSString *)js {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)updateCodeInjected {
    _codeInjected = [[self _eval:@"typeof transit" returnJSONResult:NO] isEqualToString:@"object"];
}

-(void)injectCodeToWebView {
    [self updateCodeInjected];
    if(!_codeInjected) {
        [self eval:_TRANSIT_JS_RUNTIME_CODE];
        _codeInjected = YES;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(change[NSKeyValueChangeNewKey] != self && [@[@"delegate", @"frameLoadDelegate"] containsObject:keyPath])
        @throw [NSException exceptionWithName:@"TransitException" reason:@"WebView's delegate must not be changed" userInfo:@{NSLocalizedDescriptionKey: @"WebView's delegate must not be changed"}];

    // not implemented in super class
    // [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(BOOL)proxifyEval {
    return _proxifyEval;
}

-(void)setProxifyEval:(BOOL)proxifyEval {
    _proxifyEval = proxifyEval;
}


-(id)parseJSON:(NSString*)json {
    return [_parser objectWithString:json];
}

-(void)doInvokeNative {
    // nativeInvokeTransferObject is safe to parse and contains proxy-ids
    NSString* jsReadTransferObject = [NSString stringWithFormat:@"JSON.stringify(%@.nativeInvokeTransferObject)",self.transitGlobalVarJSRepresentation];

    NSString* jsonDescription = [self _eval:jsReadTransferObject returnJSONResult:NO];
    id parsedJSON = [self parseJSON:jsonDescription];

    // try to replace markers (could fail due to disposed native proxies)
    id transferObject;
    id result;
    @try {
        transferObject = [self recursivelyReplaceMarkersWithProxies:parsedJSON];
    }
    @catch (NSException *exception) {
        result = transit_errorWithCodeFromException(3, exception);
        NSLog(@"TRANSIT-BRIDGE-ERROR: %@ (while called from JavaScript)", [result userInfo][NSLocalizedDescriptionKey]);
    }

    BOOL expectsResult = YES;

    // if was an error while replacing markers (e.g. due to disposed native function) result is filled with an NSError by now
    if(!result) {
        // transferObject is an array => this is a queue of callDescriptions
        // perform each call and ignore results
        if([transferObject isKindOfClass:NSArray.class]) {
            NSLog(@"invoke async functions in bulk of %@ elements", @([transferObject count]));
            for(NSDictionary* singleCallDescription in transferObject) {
                [self invokeNativeWithDescription:singleCallDescription];
            }
            expectsResult = NO;
        } else {
            // transferObject is a single callDescription
            // will return NSError if an exception occured
            result = [self invokeNativeWithDescription:transferObject];
        }
    }

    if(expectsResult) {
        NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
        NSString* jsResult = [TransitProxy jsRepresentation:result collectingProxiesOnScope:proxiesOnScope];
        NSString* js = [NSString stringWithFormat:@"%@.nativeInvokeTransferObject=%@", self.transitGlobalVarJSRepresentation, jsResult];
        [self _eval:js jsThisArg:@"null" collectedProxiesOnScope:proxiesOnScope returnJSResult:NO onGlobalScope:NO useAndRestoreCallScope:nil];
    }
}

-(void)setHandleRequestBlock:(TransitWebViewContextRequestHandler)testCallBlock {
    _handleRequestBlock = [testCallBlock copy];
}

-(TransitWebViewContextRequestHandler)handleRequestBlock {
    return _handleRequestBlock;
}

-(NSString *)lastEvaluatedJSCode {
    return _lastEvaluatedJSCode;
}

- (id)_eval:(NSString *)jsExpression jsThisArg:(NSString *)jsAdjustedThisArg collectedProxiesOnScope:(NSOrderedSet *)proxiesOnScope returnJSResult:(BOOL)returnJSResult onGlobalScope:(BOOL)globalScope useAndRestoreCallScope:(TransitCallScope *)callScope {
    @try {
        if(callScope) {
            [self pushCallScope:callScope];
        }

        NSString* jsApplyExpression;
        NSString* jsWrappedApplyExpression;

        if(globalScope) {
            NSParameterAssert([jsAdjustedThisArg isEqualToString:@"null"]);
            NSParameterAssert(proxiesOnScope.count == 0);
            NSParameterAssert(returnJSResult == NO);
            jsWrappedApplyExpression = jsExpression;
        } else {
            NSMutableString* jsProxiesOnScope = [NSMutableString stringWithString:@""];
            if(proxiesOnScope.count>0) {
                for(TransitProxy* p in proxiesOnScope) {
                    [jsProxiesOnScope appendFormat:@"var %@=%@;", [p _jsRepresentationCollectingProxiesOnScope:nil], p.jsRepresentationToResolveProxy];
                }
            }

            jsApplyExpression = [@"null" isEqualToString:jsAdjustedThisArg] ? jsExpression : [NSString stringWithFormat:@"function(){return %@;}.call(%@)", jsExpression, jsAdjustedThisArg];

            if(!returnJSResult) {
                jsWrappedApplyExpression = [NSString stringWithFormat:@"(function(){"
                                            "%@"
                                            "%@"
                                            "})()", jsProxiesOnScope, jsApplyExpression];
            } else {
                if(self.proxifyEval && self.codeInjected) {
                    jsWrappedApplyExpression = [NSString stringWithFormat:@"(function(){"
                                                "var result;"
                                                "try{"
                                                "%@"
                                                "result = %@;"
                                                "}catch(e){"
                                                "return {e:e.message};"
                                                "}"
                                                "return {v:%@.proxify(result)};"
                                                "})()", jsProxiesOnScope, jsApplyExpression, self.transitGlobalVarJSRepresentation];
                } else {
                    jsWrappedApplyExpression = [NSString stringWithFormat:@"(function(){"
                                                "try{"
                                                "%@"
                                                "return {v:%@};"
                                                "}catch(e){"
                                                "return {e:e.message};"
                                                "}"
                                                "})()", jsProxiesOnScope, jsApplyExpression];
                }
            }
        }

        NSString* jsonResult = [self _eval:jsWrappedApplyExpression returnJSONResult:returnJSResult];

        if(!returnJSResult)
            return nil;

        id parsedObject = [self parseJSON:jsonResult];
        if(parsedObject == nil) {
            NSException *e = [NSException exceptionWithName:@"TransitException"
                                                     reason:[NSString stringWithFormat:@"Invalid JavaScript: %@", jsApplyExpression] userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Error while evaluating JavaScript. Seems to be invalid: %@", jsApplyExpression]}];

            NSLog(@"TRANSIT-JS-ERROR: %@ while evaluating %@", e, jsApplyExpression);
            @throw e;
        }

        if(parsedObject[@"e"]) {
            NSException *e = [NSException exceptionWithName:@"TransitException" reason:parsedObject[@"e"] userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Error while executing JavaScript: %@", parsedObject[@"e"]]}];
            NSLog(@"TRANSIT-JS-ERROR: %@ while evaluating %@", e, jsApplyExpression);
            @throw e;
        }
        id parsedResult = parsedObject[@"v"];
        id enhancedResult = parsedResult;
        if(self.proxifyEval)
            enhancedResult = [self recursivelyReplaceMarkersWithProxies:parsedResult];

        return enhancedResult;
    }
    @finally {
        if(callScope) {
            [self popCallScope];
        }
    }
}

- (id)_eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)values returnJSResult:(BOOL)returnJSResult useAndRestoreCallScope:(TransitCallScope *)callScope {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;

    values = [self recursivelyReplaceBlocksWithNativeFunctions:values];
    NSString* jsExpression = [TransitProxy jsRepresentationFromCode:jsCode arguments:values collectingProxiesOnScope:proxiesOnScope];
    id adjustedThisArg = thisArg == self ? nil : thisArg;
    NSString* jsAdjustedThisArg = adjustedThisArg ? [TransitProxy jsRepresentation:thisArg collectingProxiesOnScope:proxiesOnScope] : @"null";

    return [self _eval:jsExpression jsThisArg:jsAdjustedThisArg collectedProxiesOnScope:proxiesOnScope returnJSResult:returnJSResult onGlobalScope:NO useAndRestoreCallScope:callScope];
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)values returnJSResult:(BOOL)returnJSResult {
    TransitCallScope *callScope = [[TransitEvalCallScope alloc] initWithContext:self parentScope:self.currentCallScope thisArg:thisArg jsCode:jsCode values:values expectsResult:returnJSResult];
    return [self _eval:jsCode thisArg:thisArg values:values returnJSResult:returnJSResult useAndRestoreCallScope:callScope];
}

@end

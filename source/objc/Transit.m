//
//  Transit.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "Transit.h"
#import "Transit+Private.h"
#import "SBJson.h"
#import "SBJsonStreamWriterAccumulator.h"
#import "SBJsonStreamWriterState.h"
#import <objc/runtime.h>

@implementation NSString(Transit)

void * _TRANSIT_ASSOC_KEY_IS_JS_EXPRESSION = &_TRANSIT_ASSOC_KEY_IS_JS_EXPRESSION;

-(NSString*)stringAsJSExpression {
    if(self.isJSExpression)
        return self;
    
    NSString *result = [NSString stringWithFormat:@"%@", self];
    objc_setAssociatedObject(result, _TRANSIT_ASSOC_KEY_IS_JS_EXPRESSION, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return result;
}

-(BOOL) isJSExpression {
    id assoc = objc_getAssociatedObject(self, _TRANSIT_ASSOC_KEY_IS_JS_EXPRESSION);
    return [assoc boolValue];
}

@end

id TransitNilSafe(id valueOrNil) {
    return valueOrNil ? valueOrNil : @"undefined".stringAsJSExpression;
}

@implementation NSString(TransRegExp)

-(NSString*)stringByReplacingMatchesOf:(NSRegularExpression*)regex withTransformation:(NSString*(^)(NSString*element)) block {

    NSMutableString* mutableString = [self mutableCopy];
    NSInteger offset = 0;

    for (NSTextCheckingResult* result in [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)]) {
        
        NSRange resultRange = [result range];
        resultRange.location += offset;
        
        NSString* match = [regex replacementStringForResult:result
                                                   inString:mutableString
                                                     offset:offset
                                                   template:@"$0"];

        NSString* replacement = block(match);
        
        // make the replacement
        [mutableString replaceCharactersInRange:resultRange withString:replacement];
        
        // update the offset based on the replacement
        offset += ([replacement length] - resultRange.length);
    }
    return mutableString;
}

@end

@interface TransitJSRepresentationStreamWriter : SBJsonStreamWriter

@property (nonatomic, unsafe_unretained) SBJsonStreamWriterState *state; // Internal
@property(nonatomic, strong) NSMutableOrderedSet* proxiesOnScope;

@end

@implementation TransitJSRepresentationStreamWriter

-(BOOL)writeValue:(id)value {
    // nil -> undefined
    if(value == nil)
        return [self writeJSExpression:@"undefined"];
    
    // NSString marked as jsExpression -> jsEpxression
    if([value isKindOfClass:NSString.class] && [value isJSExpression])
        return [self writeJSExpression:value];
    
    // TransitProxy -> must provide own representation
    if([value isKindOfClass:TransitProxy.class]) {
        TransitProxy* proxy = (TransitProxy*)value;
        NSString* jsRepresentation = [proxy _jsRepresentationCollectingProxiesOnScope:self.proxiesOnScope];
        if(jsRepresentation == nil) {
            self.error = [NSString stringWithFormat:@"TransitProxy %@ has no jsRepresentation", value];
            return NO;
        }
        
        return [self writeJSExpression:jsRepresentation];
    }
    // NSError -> new Error(desc)
    if([value isKindOfClass:NSError.class]) {
        NSString* desc = [value userInfo][NSLocalizedDescriptionKey];
        NSString* jsExpression = [NSString stringWithFormat:@"new Error(%@)", [TransitProxy jsRepresentation:desc collectingProxiesOnScope:self.proxiesOnScope]];
        return [self writeJSExpression:jsExpression];
    }
    
    // any valid JSON value
    return [super writeValue:value];
}

-(BOOL)writeJSExpression:(NSString*)jsExpression {
	if ([self.state isInvalidState:self]) return NO;
	if ([self.state expectingKey:self]) return NO;
	[self.state appendSeparator:self];
	if (self.humanReadable) [self.state appendWhitespace:self];
    
	NSData *data = [jsExpression dataUsingEncoding:NSUTF8StringEncoding];
    [self.delegate writer:self appendBytes:data.bytes length:data.length];

	[self.state transitionState:self];
	return YES;
}

@end

@implementation TransitProxy {
    NSString* _proxyId;
    __weak TransitContext* _rootContext;
}

-(id)initWithRootContext:(TransitContext*)rootContext proxyId:(NSString*)proxyId {
    self = [self init];
    if(self) {
        _rootContext = rootContext;
        _proxyId = proxyId;
    }
    return self;
}

-(id)initWithRootContext:(TransitContext*)rootContext value:(id)value {
    self = [self init];
    if(self){
        _rootContext = rootContext;
        _value = value;
    }
    return self;
}

-(id)initWithRootContext:(TransitContext *)rootContext jsRepresentation:(NSString*)jsRepresentation {
    return [self initWithRootContext:rootContext value:jsRepresentation.stringAsJSExpression];
}


-(id)initWithRootContext:(TransitContext*)rootContext {
    return [self initWithRootContext:rootContext proxyId:nil];
}

-(void)dealloc {
    [self dispose];
}

-(BOOL)disposed {
    return _rootContext == nil;
}

-(void)clearRootContextAndProxyId {
    _rootContext = nil;
    _proxyId = nil;
}

-(void)dispose {
    if(_rootContext) {
        if(_proxyId){
            [_rootContext releaseJSProxyWithId: _proxyId];
        }
        [self clearRootContextAndProxyId];
    }
}

-(NSString*)proxyId {
    return _proxyId;
}

-(TransitContext*)rootContext{
    return _rootContext;
}

-(id)eval:(NSString*)jsCode {
    return [self eval:jsCode thisArg:self arguments:@[] returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode arg:(id)arg0 {
    return [self eval:jsCode thisArg:self arguments:@[TransitNilSafe(arg0)] returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode arg:(id)arg0 arg:(id)arg1 {
    return [self eval:jsCode thisArg:self arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)] returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode arg:(id)arg0 arg:(id)arg1 arg:(id)arg2 {
    return [self eval:jsCode thisArg:self arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1), TransitNilSafe(arg2)] returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode arguments:(NSArray*)arguments {
    return [self eval:jsCode thisArg:self arguments:arguments returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg {
    return [self eval:jsCode thisArg:thisArg arguments:@[] returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arg:(id)arg0 {
    return [self eval:jsCode thisArg:thisArg arguments:@[TransitNilSafe(arg0)] returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arg:(id)arg0 arg:(id)arg1 {
    return [self eval:jsCode thisArg:thisArg arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)] returnJSResult:YES];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arguments:(NSArray*)arguments {
    return [self eval:jsCode thisArg:thisArg arguments:arguments returnJSResult:YES];
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg arguments:(NSArray *)arguments returnJSResult:(BOOL)returnJSResult {
    return [_rootContext eval:jsCode thisArg:thisArg arguments:arguments returnJSResult:returnJSResult];
}

-(NSString*)jsRepresentationToResolveProxy {
    if(_proxyId && _rootContext)
        return [_rootContext jsRepresentationToResolveProxyWithId:_proxyId];
    
    @throw [NSException exceptionWithName:@"TransitException" reason:@"Internal Error: Proxy cannot be resolved" userInfo:nil];
}

-(NSString*)_jsRepresentationCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    if(_proxyId && _rootContext) {
        [proxiesOnScope addObject:self];
        return [_rootContext jsRepresentationForProxyWithId:_proxyId];
    }
    
    if(_value) {
        return [self.class jsRepresentation:_value collectingProxiesOnScope:proxiesOnScope];
    }
    
    return nil;
}

+(NSString*)jsRepresentation:(id)object collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    SBJsonStreamWriterAccumulator *accumulator = [[SBJsonStreamWriterAccumulator alloc] init];
    
	TransitJSRepresentationStreamWriter *streamWriter = [[TransitJSRepresentationStreamWriter alloc] init];
    streamWriter.delegate = accumulator;
    streamWriter.proxiesOnScope = proxiesOnScope;
    
    BOOL ok = [streamWriter writeValue:object];
    if(!ok) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"cannot be represented as JS (%@): %@", streamWriter.error, object] userInfo:nil];
    }
    
    return [NSString.alloc initWithData:accumulator.data encoding:NSUTF8StringEncoding];
}

+(NSString*)jsExpressionFromCode:(NSString*)jsCode arguments:(NSArray*)arguments collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    if(jsCode.isJSExpression) {
        if(arguments.count > 0)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"jsExpression cannot take any additional arguments" userInfo:nil];
        return jsCode;
    }
    
    NSError* error;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"@"
                                  options:0
                                  error:&error];
    
    NSMutableArray* mutableArguments = [arguments mutableCopy];
    jsCode = [jsCode stringByReplacingMatchesOf:regex withTransformation:^(NSString* match){
        if(mutableArguments.count <=0)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"too few arguments" userInfo:nil];
        
        id elem = mutableArguments[0];
        NSString* jsRepresentation = [self jsRepresentation:elem collectingProxiesOnScope:proxiesOnScope];
        NSString* result =  [NSString stringWithFormat:@"%@", jsRepresentation];
        
        [mutableArguments removeObjectAtIndex:0];
        return result;
    }];
    
    if(mutableArguments.count >0)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"too many arguments" userInfo:nil];
    
    return jsCode.stringAsJSExpression;
}

@end

NSUInteger _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT = 0;
NSString* _TRANSIT_MARKER_PREFIX_JS_FUNCTION_ = @"__TRANSIT_JS_FUNCTION_";
NSString* _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_ = @"__TRANSIT_OBJECT_PROXY_";
NSString* _TRANSIT_MARKER_PREFIX_NATIVE_FUNCTION = @"__TRANSIT_NATIVE_FUNCTION_";

@implementation TransitContext {
    NSMutableDictionary* _retainedNativeProxies;
    int _lastNativeFunctionId;
}

-(id)init {
    self = [super init];
    if(self){
        _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT++;
        _retainedNativeProxies = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)dealloc {
    // dispose manually from here to maintain correct life cycle
    [self disposeAllNativeProxies];
    _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT--;
}

-(void)dispose {
    [self disposeAllNativeProxies];
}

-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId {
    return proxyId;
}

-(NSString*)jsRepresentationToResolveProxyWithId:(NSString*)proxyId {
    return [[NSString stringWithFormat:@"%@.r(\"%@\")", self.transitGlobalVarJSExpression, proxyId] stringAsJSExpression];
}

-(NSString*)jsRepresentationForNativeFunctionWithId:(NSString*)proxyId {
    return proxyId;
}

-(NSString*)jsRepresentationToResolveNativeFunctionWithId:(NSString*)proxyId {
    return [[NSString stringWithFormat:@"%@.nativeFunction(\"%@\")", self.transitGlobalVarJSExpression, proxyId] stringAsJSExpression];
}

-(void)disposeAllNativeProxies {
    for (id proxy in _retainedNativeProxies.allValues) {
        [proxy dispose];
    }
}

-(void)releaseJSProxyWithId:(NSString*)id {
//    NSLog(@"release proxy with id %@", id);
    [self eval:@"@.releaseElementWithId(@)" thisArg:nil arguments:@[self.transitGlobalVarJSExpression, id] returnJSResult:NO];
}

-(NSString*)nextNativeFunctionId {
    return [NSString stringWithFormat:@"%@%d", _TRANSIT_MARKER_PREFIX_NATIVE_FUNCTION, ++_lastNativeFunctionId];
}

-(TransitFunction*)functionWithBlock:(TransitFunctionBlock)block {
    TransitNativeFunction* function = [[TransitNativeFunction alloc] initWithRootContext:self nativeId:[self nextNativeFunctionId] block:block];
    [self retainNativeProxy:function];
    return function;
}

-(TransitFunction*)functionWithDelegate:(id<TransitFunctionBodyProtocol>)delegate {
    return [self functionWithBlock:^id(TransitProxy *thisArg, NSArray *arguments) {
        return [delegate callWithThisArg:thisArg arguments:arguments];
    }];
}


-(TransitFunction*)replaceFunctionAt:(NSString*)path withFunctionWithBlock:(TransitReplaceFunctionBlock)block {
    TransitFunction *original = [self eval:path];
    if(!original)
        return nil;
    
    TransitFunction *function = [self functionWithBlock:^id(TransitProxy *thisArg, NSArray *arguments) {
        return block(original, thisArg, arguments);
    }];
    
    [self eval:@"@ = @" arguments:@[path.stringAsJSExpression, function]];
    
    return function;
}


-(void)retainNativeProxy:(TransitProxy*)proxy {
    NSParameterAssert(proxy.rootContext == self);
    NSParameterAssert(proxy.proxyId);
    
//    if(_retainedNativeProxies[proxy.proxyId])
//        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"cannot retain native proxy twice" userInfo:nil];
    
    _retainedNativeProxies[proxy.proxyId] = proxy;
}

-(void)releaseNativeProxy:(TransitProxy *)proxy {
    NSParameterAssert(proxy.rootContext == self);
    NSParameterAssert(proxy.proxyId);
    
//    id existing = _retainedNativeProxies[proxy.proxyId];
//    if(!existing)
//        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"cannot release unretained proxy" userInfo:nil];

    [_retainedNativeProxies removeObjectForKey:proxy.proxyId];
}

-(NSDictionary*)retainedNativeProxies {
    return _retainedNativeProxies;
}

-(NSString*)transitGlobalVarJSExpression {
    return @"transit".stringAsJSExpression;
}

+(NSRegularExpression*)regularExpressionForMarker:(NSString*)marker {
    static NSMutableDictionary* cache;
    if(!cache)cache = [NSMutableDictionary dictionary];
    
    NSRegularExpression *result = cache[marker];
    if(!result) {
        NSString* pattern = [NSString stringWithFormat:@"^%@([\\d\\w]+)$", [NSRegularExpression escapedPatternForString:marker]];
        result = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        cache[marker] = result;
    }
    return result;
}

+(id)proxyIdFromString:(NSString*)string forMarker:(NSString*)marker {
    NSRegularExpression* expression = [self regularExpressionForMarker:marker];
    NSTextCheckingResult *match = [expression firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if(match) {
        return [string substringWithRange:[match rangeAtIndex:0]];
    }
    return nil;
}

-(id)recursivelyReplaceMarkersWithProxies:(id)unproxified {
    // TODO: correctly parse native functions
    
    if([unproxified isKindOfClass:NSString.class]) {
        id objectProxyId = [self.class proxyIdFromString:unproxified forMarker:_TRANSIT_MARKER_PREFIX_OBJECT_PROXY_];
        if(objectProxyId)
            return [[TransitProxy alloc] initWithRootContext:self proxyId:objectProxyId];
        
        id functionProxyId = [self.class proxyIdFromString:unproxified forMarker:_TRANSIT_MARKER_PREFIX_JS_FUNCTION_];
        if(functionProxyId)
            return [[TransitJSFunction alloc] initWithRootContext:self proxyId:functionProxyId];
    }
    if([unproxified isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:unproxified];
        for (id key in dict.allKeys) {
            dict[key] = [self recursivelyReplaceMarkersWithProxies:dict[key]];
        }
        return dict;
    }
    if([unproxified isKindOfClass:NSArray.class]) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:unproxified];
        for(int i=0; i<array.count; i++)
            array[i] = [self recursivelyReplaceMarkersWithProxies:array[i]];
        return array;
    }

    return unproxified;
}

-(id)invokeNativeDescription:(NSDictionary*)description {
    id nativeProxyId = description[@"nativeId"];
    TransitFunction *func = _retainedNativeProxies[nativeProxyId];
    
    if(!func)
        return [NSError errorWithDomain:@"transit" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"no native function with id: %@", nativeProxyId]}];
    
    id thisArg = description[@"thisArg"];
    NSArray *arguments = description[@"args"];
    @try {
        id result = [func callWithThisArg:thisArg arguments:arguments];
        return result;
    }
    @catch (NSException *exception) {
        NSString *desc = exception.userInfo[NSLocalizedDescriptionKey] ? exception.userInfo[NSLocalizedDescriptionKey] : [NSString stringWithFormat:@"%@: %@", exception.name, exception.reason];
        NSLog(@"TRANSIT-NATIVE-ERROR: %@ while called from javascript with arguments %@", desc, arguments);
        return [NSError errorWithDomain:@"transit" code:5 userInfo:@{NSLocalizedDescriptionKey: desc}];
    }
    @finally {

    }
}

-(id)invokeNativeFunc:(TransitNativeFunction*)func thisArg:(id)thisArg arguments:(NSArray*)arguments {
    if(thisArg == nil || thisArg == NSNull.null) {
        thisArg = self;
    } else
        if(![thisArg isKindOfClass:TransitProxy.class])
            thisArg = [[TransitProxy alloc] initWithRootContext:self value:thisArg];
    
    return [func callWithProxifedThisArg:thisArg proxifiedArguments:arguments];
}


@end

TransitUIWebViewContextRequestHandler _TRANSIT_DEFAULT_UIWEBVIEW_REQUEST_HANDLER = ^(TransitUIWebViewContext* ctx,NSURLRequest* request) {
    [ctx invokeNative];
};

@implementation TransitUIWebViewContext{
    TransitUIWebViewContextRequestHandler _handleRequestBlock;
    BOOL _proxifiedEval;
    BOOL _codeInjected;
    SBJsonParser *_parser;
    NSString* _lastEvaluatedJSCode;
    id<UIWebViewDelegate> _originalDelegate;
}

-(void)setHandleRequestBlock:(TransitUIWebViewContextRequestHandler)testCallBlock {
    _handleRequestBlock = [testCallBlock copy];
}

-(TransitUIWebViewContextRequestHandler)handleRequestBlock {
    return _handleRequestBlock;
}

-(BOOL)proxifyEval {
    return _proxifiedEval;
}

-(void)setProxifyEval:(BOOL)proxifyEval {
    _proxifiedEval = proxifyEval;
}

-(NSString *)lastEvaluatedJSCode {
    return _lastEvaluatedJSCode;
}

NSString* _TRANSIT_SCHEME = @"transit";
NSString* _TRANSIT_URL_TESTPATH = @"testcall";

+(id)contextWithUIWebView:(UIWebView*)webView {
    return [[self alloc] initWithUIWebView: webView];
}

-(id)initWithUIWebView:(UIWebView*)webView {
    self = [self init];
    if(self) {
        _webView = webView;
        _handleRequestBlock = _TRANSIT_DEFAULT_UIWEBVIEW_REQUEST_HANDLER;
        _parser = SBJsonParser.new;
        _proxifiedEval = YES;
        [self bindToWebView];
    }
    return self;
}

-(void)dealloc {
    [_webView removeObserver:self forKeyPath:@"delegate"];
}

-(void)updateCodeInjected {
    _codeInjected = [[self _eval:@"typeof transit"] isEqualToString:@"\"object\""];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(change[NSKeyValueChangeNewKey] != self)
        @throw [NSException exceptionWithName:@"TransitException" reason:@"UIWebView.delegate must not be changed" userInfo:@{NSLocalizedDescriptionKey: @"UIWebView.delegate must not be changed"}];
                
    // not implemented in super class
    // [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void)bindToWebView {
    _originalDelegate = _webView.delegate;
    _webView.delegate = self;
    [_webView addObserver:self forKeyPath:@"delegate" options:NSKeyValueObservingOptionNew context:nil];
    [self injectCodeToWebView];
}

-(void)injectCodeToWebView {
    [self updateCodeInjected];
    if(!_codeInjected) {
        [self eval:_TRANSIT_JS_RUNTIME_CODE];
        _codeInjected = YES;
    }
}

-(id)parseJSON:(NSString*)json {
    return [_parser objectWithString:json];
}

-(NSString*)_eval:(NSString*)js {
    _lastEvaluatedJSCode = [NSString stringWithFormat: @"JSON.stringify(%@)", js];
    return [_webView stringByEvaluatingJavaScriptFromString: _lastEvaluatedJSCode];
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg arguments:(NSArray *)arguments returnJSResult:(BOOL)returnJSResult {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    
    NSString* jsExpression = [self.class jsExpressionFromCode:jsCode arguments:arguments collectingProxiesOnScope:proxiesOnScope];
    id adjustedThisArg = thisArg == self ? nil : thisArg;
    NSString* jsAdjustedThisArg = adjustedThisArg ? [TransitProxy jsRepresentation:thisArg collectingProxiesOnScope:proxiesOnScope] : @"null";
    
    NSMutableString* jsProxiesOnScope = [NSMutableString stringWithString:@""];
    if(proxiesOnScope.count>0) {
        for(TransitProxy* p in proxiesOnScope) {
            [jsProxiesOnScope appendFormat:@"var %@=%@;", [p _jsRepresentationCollectingProxiesOnScope:nil], p.jsRepresentationToResolveProxy];
        }
    }
    
    NSString* jsApplyExpression = jsAdjustedThisArg ? [NSString stringWithFormat:@"function(){return %@;}.call(%@)", jsExpression, jsAdjustedThisArg] : jsExpression;
    NSString* jsWrappedApplyExpression;
    if(_proxifiedEval && _codeInjected) {
        jsWrappedApplyExpression = [NSString stringWithFormat:@"(function(){"
                                    "var result;"
                                    "try{"
                                        "%@"
                                        "result = %@;"
                                    "}catch(e){"
                                        "return {e:e.message};"
                                    "}"
                                    "return {v:%@.proxify(result)};"
                                    "})()", jsProxiesOnScope, jsApplyExpression, self.transitGlobalVarJSExpression];
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
    
    NSString* jsonResult = [self _eval:jsWrappedApplyExpression];

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
    if(_proxifiedEval)
        enhancedResult = [self recursivelyReplaceMarkersWithProxies:parsedResult];
    
    return enhancedResult;
}

-(void)invokeNative {
    // nativeInvokeTransferObject is safe to parse and contains proxy-ids
    NSString* jsReadTransferObject = [NSString stringWithFormat:@"JSON.stringify(%@.nativeInvokeTransferObject)", self.transitGlobalVarJSExpression];
    NSString* jsonDescription = [self.webView stringByEvaluatingJavaScriptFromString:jsReadTransferObject];
    id callDescription = [self recursivelyReplaceMarkersWithProxies:[self parseJSON:jsonDescription]];
    
    // actually perform call
    id result = [self invokeNativeDescription:callDescription];
    
    // simple assignment is safe to evaluate
//    NSString* jsWriteTransferObject = [NSString stringWithFormat:@"%@.nativeInvokeTransferObject=%@", self.transitGlobalVarJSExpression, [TransitProxy jsRepresentation:result]];
//    [self.webView stringByEvaluatingJavaScriptFromString:jsWriteTransferObject];
    
    // TODO: check how to increase performance, again
    [self eval:@"@.nativeInvokeTransferObject=@" thisArg:nil arguments:@[self.transitGlobalVarJSExpression,TransitNilSafe(result)] returnJSResult:NO];
}

#pragma UIWebViewDelegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if([request.URL.scheme isEqual:_TRANSIT_SCHEME]){
        if(self.handleRequestBlock)
            self.handleRequestBlock(self, request);
        
        return NO;
    }
    
    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    
    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webViewDidStartLoad:webView];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self injectCodeToWebView];
    
    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webViewDidFinishLoad:webView];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webView:webView didFailLoadWithError:error];
}

@end

@implementation TransitFunction

-(id)call {
    return [self callWithThisArg:nil arguments:@[] returnResult:YES];
}

-(id)callWithArg:(id)arg0 {
    return [self callWithThisArg:nil arguments:@[TransitNilSafe(arg0)] returnResult:YES];
}
            
-(id)callWithArg:(id)arg0 arg:(id)arg1 {
    return [self callWithThisArg:nil arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)] returnResult:YES];
}

-(id)callWithArg:(id)arg0 arg:(id)arg1 arg:(id)arg2 {
    return [self callWithThisArg:nil arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1), TransitNilSafe(arg2)] returnResult:YES];
}

-(id)callWithArguments:(NSArray*)arguments {
    return [self callWithThisArg:nil arguments:arguments returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg {
    return [self callWithThisArg:thisArg arguments:@[] returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arg:(id)arg0 {
    return [self callWithThisArg:thisArg arguments:@[TransitNilSafe(arg0)] returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arg:(id)arg0 arg:(id)arg1 {
    return [self callWithThisArg:thisArg arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)] returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments {
    return [self callWithThisArg:thisArg arguments:arguments returnResult:YES];
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult {
    @throw [NSException exceptionWithName:@"Abstract" reason:@"must be implemented by subclass" userInfo:nil];;
}

-(void)callAsync {
    [self callAsyncWithThisArg:nil arguments:@[]];
}

-(void)callAsyncWithArg:(id)arg0 {
    [self callAsyncWithThisArg:nil arguments:@[TransitNilSafe(arg0)]];
}

-(void)callAsyncWithArg:(id)arg0 arg:(id)arg1 {
    [self callAsyncWithThisArg:nil arguments:@[TransitNilSafe(arg0), TransitNilSafe(arg1)]];
}

-(void)callAsyncWithArguments:(NSArray*)arguments {
    [self callAsyncWithThisArg:nil arguments:arguments];
}

-(void)callAsyncWithThisArg:(id)thisArg arguments:(NSArray*)arguments {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self callWithThisArg:thisArg arguments:arguments returnResult:NO];
    });
}


@end

@implementation TransitNativeFunction

-(id)initWithRootContext:(TransitContext *)rootContext nativeId:(NSString*)nativeId block:(TransitFunctionBlock)block {
    self = [self initWithRootContext:rootContext proxyId:nativeId];
    if(self) {
        NSParameterAssert(nativeId);
        NSParameterAssert(block);
        _block = block;
    }
    return self;
}

-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments returnResult:(BOOL)returnResult {
    id result = [self.rootContext invokeNativeFunc:self thisArg:thisArg arguments:arguments];
    return returnResult ? result : nil;
}

-(id)callWithProxifedThisArg:(TransitProxy*)thisArg proxifiedArguments:(NSArray*)arguments {
    return _block(thisArg, arguments);
}

-(NSString*)_jsRepresentationCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope {
    [proxiesOnScope addObject:self];
    return [self.rootContext jsRepresentationForNativeFunctionWithId:self.proxyId];
}

-(NSString*)jsRepresentationToResolveProxy {
    return [self.rootContext jsRepresentationToResolveNativeFunctionWithId:self.proxyId];
}

-(void)dispose {
    if(self.rootContext) {
        if(self.proxyId)
            [self.rootContext releaseNativeProxy:self];
        [self clearRootContextAndProxyId];
    }
}

@end


@implementation TransitJSFunction

-(id)callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult {
    if(self.disposed)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"function already disposed" userInfo:nil];
    
    // most frequent cases: zore or one argument, no specific this arg
//    BOOL noSpecificThisArg = (thisArg == nil) || (thisArg == self.rootContext);
    
    // TODO: re-enable shortcuts
//    if(noSpecificThisArg && arguments.count == 0) {
//        NSString* js = [NSString stringWithFormat:@"%@()", self.jsRepresentation];
//        return [self.rootContext eval:js thisArg:nil arguments:nil returnJSResult:returnResult];
//    }
//    if(noSpecificThisArg && arguments.count == 1) {
//        NSString* js = [NSString stringWithFormat:@"%@(%@)", self.jsRepresentation, [TransitProxy jsRepresentation:arguments[0]] ];
//        return [self.rootContext eval:js thisArg:nil arguments:nil returnJSResult:returnResult];
//    }
//    if(noSpecificThisArg && arguments.count == 2) {
//        NSString* js = [NSString stringWithFormat:@"%@(%@,%@)", self.jsRepresentation, [TransitProxy jsRepresentation:arguments[0]], [TransitProxy jsRepresentation:arguments[1]] ];
//        return [self.rootContext eval:js thisArg:nil arguments:nil returnJSResult:returnResult];
//    }

    // general case
//    NSString* js = [[NSString stringWithFormat:@"%@.apply(this, %@)", self.jsRepresentation, [TransitProxy jsRepresentation:arguments]] stringAsJSExpression];
//    return [self.rootContext eval:js thisArg:thisArg arguments:@[] returnJSResult:returnResult];
    
    return [self.rootContext eval:@"@.apply(this,@)" thisArg:thisArg arguments:@[self, (arguments?arguments:@[])] returnJSResult:returnResult];
}

@end

// NOTE: this value is automatically generated by grunt. DO NOT CHANGE ANYTHING BEHIND THIS LINE
NSString* _TRANSIT_JS_RUNTIME_CODE = @
    // _TRANSIT_JS_RUNTIME_CODE_START
    "(function(){/*global Document Element */\n\n(function(globalName){\n    var transit = {\n        retained:{},\n        lastRetainId: 0\n    };\n\n    var PREFIX_MAGIC_FUNCTION = \"__TRANSIT_JS_FUNCTION_\";\n    var PREFIX_MAGIC_NATIVE_FUNCTION = \"__TRANSIT_NATIVE_FUNCTION_\";\n    var PREFIX_MAGIC_OBJECT = \"__TRANSIT_OBJECT_PROXY_\";\n\n    var GLOBAL_OBJECT = window;\n\n    transit.doInvokeNative = function(invocationDescription){\n        throw \"must be replaced by native runtime \" + invocationDescription;\n    };\n\n    transit.nativeFunction = function(nativeId){\n        var f = function(){\n            return transit.invokeNative(nativeId, this, arguments);\n        };\n        f.transitNativeId = PREFIX_MAGIC_NATIVE_FUNCTION + nativeId;\n        return f;\n    };\n\n    transit.recursivelyProxifyMissingFunctionProperties = function(missing, existing) {\n        for(var key in existing) {\n            if(existing.hasOwnProperty(key)) {\n                var existingValue = existing[key];\n\n                if(typeof existingValue === \"function\") {\n                    missing[key] = transit.proxify(existingValue);\n                }\n                if(typeof existingValue === \"object\" && typeof missing[key] === \"object\" && missing[key] !== null) {\n                    transit.recursivelyProxifyMissingFunctionProperties(missing[key], existingValue);\n                }\n            }\n        }\n    };\n\n    transit.proxify = function(elem) {\n        if(typeof elem === \"function\") {\n            if(typeof elem.transitNativeId !== \"undefined\") {\n                return elem.transitNativeId;\n            } else {\n                return transit.retainElement(elem);\n            }\n        }\n\n        if(typeof elem === \"object\") {\n            if(elem instanceof Document || elem instanceof Element) {\n                return transit.retainElement(elem);\n            }\n\n            var copy;\n            try {\n                copy = JSON.parse(JSON.stringify(elem));\n            } catch (e) {\n                return transit.retainElement(elem);\n            }\n            transit.recursivelyProxifyMissingFunctionProperties(copy, elem);\n            return copy;\n        }\n\n        return elem;\n    };\n\n    transit.invokeNative = function(nativeId, thisArg, args) {\n        var invocationDescription = {\n            nativeId: nativeId,\n            thisArg: (thisArg === GLOBAL_OBJECT) ? null : transit.proxify(thisArg),\n            args: []\n        };\n\n        for(var i = 0;i<args.length; i++) {\n            invocationDescription.args.push(transit.proxify(args[i]));\n        }\n\n        return transit.doInvokeNative(invocationDescription);\n    };\n\n    transit.retainElement = function(element){\n        transit.lastRetainId++;\n        var id = \"\" + transit.lastRetainId;\n        if(typeof element === \"object\") {\n            id = PREFIX_MAGIC_OBJECT + id;\n        }\n        if(typeof element === \"function\") {\n            id = PREFIX_MAGIC_FUNCTION + id;\n        }\n\n        transit.retained[id] = element;\n        return id;\n    };\n\n    transit.r = function(retainId) {\n        return transit.retained[retainId];\n    };\n\n    transit.releaseElementWithId = function(retainId) {\n        if(typeof transit.retained[retainId] === \"undefined\") {\n            throw \"no retained element with Id \" + retainId;\n        }\n\n        delete transit.retained[retainId];\n    };\n\n    window[globalName] = transit;\n\n})(\"transit\");(function(globalName){\n    var transit = window[globalName];\n\n    var callCount = 0;\n    transit.doInvokeNative = function(invocationDescription){\n        invocationDescription.callNumber = ++callCount;\n        transit.nativeInvokeTransferObject = invocationDescription;\n\n        var iFrame = document.createElement('iframe');\n        iFrame.setAttribute('src', 'transit:'+callCount);\n\n        /* this call blocks until native code returns */\n        /* native ccde reads from and writes to transit.nativeInvokeTransferObject */\n        document.documentElement.appendChild(iFrame);\n\n        /* free resources */\n        iFrame.parentNode.removeChild(iFrame);\n        iFrame = null;\n\n        if(transit.nativeInvokeTransferObject === invocationDescription) {\n            throw new Error(\"internal error with transit: invocation transfer object not filled.\");\n        }\n        var result = transit.nativeInvokeTransferObject;\n        if(result instanceof Error) {\n            throw result;\n        } else {\n            return result;\n        }\n    };\n\n})(\"transit\");})()"
    // _TRANSIT_JS_RUNTIME_CODE_END
    ;
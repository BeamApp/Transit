# Transit

Transit bridges between JavaScript and iOS, OSX, Android. You can easily embed a WebView or scripted logic via JS into your application and pass in native code as functions and especially event handlers. Whenever your native code got called you can use all arguments as well as the `this` argument even if they are JavaScript, functions again!

It does not rely on special JavaScript runtimes such as JavaScript Core or Rhino but can be used with any visual or non-visual component that understands JavaScript. That way, you can easily modify existing web pages to integrate with your native application (e.g. make `history.go(-1)` close the WebView or bind a button's `onClick` event to your native code). On the other hand, you can expose native functionality as accessible JavaScript functions (e.g. `[transit bind:<native code> toVariable:'navigator.vibrate']`).

## Example for Objective-C

This example creates a transit context from a webview and binds a native callback to `jQuery(document).ready`.

```
TransitContext transit = [TransitContext transitContextWithWebView:someWebView];

TransitNativeFunc* callback = [transit nativeFuncWithBlock:^(TransitContext* _this, NSArray* arguments){
    // _this points to document as it has been called by jQuery
    // you can easily access properties from _this 
	NSLog(@"page %@ has been loaded", _this[@"title"]);
	
	// in the current context, call any javascript, again
 	[_this eval:@"alert(this.title)"] 
}];

// returns TransitContext as Proxy
arr = [transit eval:@"jQuery(document).ready(%@)" arguments:callback];
```

TBD: Another Example with callbacks

## JavaScript Proxies

In cases where Transit cannot give you access to a JavaScript value directly (e.g. a complex DOM element or for `_this`) you will get a `TransitProxy` instead.

TBD: more in-depth explanation.

![Class Diagram: Transit Proxies](http://yuml.me/diagram/dir:LR;scale:80;/class/[TransitProxy|valueType;boolValue;intValue;floatValue;stringValue;listValue;dictValue;rootContext|objectForKey:;objectAtIndex:;objectForKeyPath:|eval:;eval:arguments:;eval:context:arguments:;functionWithBlock:;]^-[TransitFunction],
[TransitFunction|call;callWithArguments:;callWithContext:arguments:]^-[TransitJSFunction],
[TransitFunction]^-[TransitNativeFunction|dispose],
[TransitProxy]^-[TransitUndefined],
[TransitProxy]^-[TransitString],
[TransitProxy]^-[TransitBoolean],
[TransitProxy]^-[TransitNumber],
[TransitProxy]^-[TransitContext|webView|addDisposer:;addExtension:],
)

## Limitations

 - no modification on passed arguments
 - life-time management for native functions has to be done manually
 - iPhone cannot handle more than 63 reentrant back to webview
	=> Unit Test this
 
### TBD: notes on disposing native functions

 - Use `TransitProxy.disposeCurrentFunction` as workaround to easily dispose current func?
 - or `TransitProxy.disposeAllAfterAnyCalled(f1, f2, f2)` ?
 - or `TransitNativeFunction.disposeAfterCalled` and `f1.disposeTogetherWithAfterAnyCalled(f2, f3)`
 - or should there be a `TransitProxy.rootContext` with `TransitContext` that supports guards?
 

## Internals

### JavaScript Side 

On Javascript Side, there's a single `transit` object with a few functions.

#### `nativeFunction(nativeId)`

Used to create native call-outs. Any native call like

	[transit eval:@"alert(%@)" arguemnts:nativeFunction];
	
will be translated to

	alert(transit.nativeFunction('SomeId'));

Internally, it's a factory to create this wrapper:

	reateNative = (nativeId) ->
	  f = -> transit.invokeNative(nativeId, this, arguments)
	  f.nativeId = nativeId
	  f

#### `invokeNative(nativeId, thisArg, otherArgs)`

Never called directly, but called from `nativeFunction(nativeId)` instead. It first builds a  `invocationDescription = {nativeId: nativeId, arguments:[]}` object from each element of `otherArgs` by analyzing its nature and *push* a suitable value as argument to the `invocationDescription`. Each element falls into one of the following cases:

1. `typeof element == "function"`
    a. it's a native wrapper, then *push* "magic native function id"  
    b. otherwise retain func with new Id, *push* "magic function id"
2. `JSON.stringify(element)` fails -> retain element with new id, *push* "magic obj id"
3. `value = JSON.stringify(element)` succeeds
	1. parse again with `obj = JSON.parse(value)` (strips off any function, values become `null`)
	2. recursively iterate over `obj` and `element`. For each function that has been stripped:
		1. retain function 
		2. store "magic function id" at missing property
	3. *push* `obj`

Similar to these steps, it stores `thisArg` as `invocationDescription.thisArg` before finishing with `return transit.doInvokeNative(invocationDescription)`.

#### `doInvokeNative(invocationDescription)`

This function has to be overriden by the native runtime to provide a blocked call-out. It must return the result as proper JavaScript value.

#### `releaseProxy(funcOrObjId)`

Releases a previously retained reference to a function or an object. Will be called from the native runtime when this proxy is not needed anymore.

#### magic values

Several functions rely on so-called "magic ids". Here's how they look like:

1. `__TRANSIT_JS_FUNCTION_<ID>`
2. `__TRANSIT_OBJECT_PROXY_<ID>`
3. `__TRANSIT_NATIVE_FUNCTION_<ID>`
 
Values for 1. and 2. are created on the JavaScript side. Values for 3. are an implementation detail from the native runtime.

*NOTE:* To prevent misuse, make sure that these IDs are unique over time.


### Native Side

TBD: more meat

#### Proxies
  
```
// [arg[2] call]
  -> (transit.retained[objId])()
// [arg[2] callWithArguments:@"some"]  
  -> (transit.retained[objId])("some")
```

```
resolveProxy(objId) // expression that represents obj objID in JS context
 (transit.retained[objId])
```	

#### Life Time

The finalizers of a `TransitJSFunction` and `TransitObject` must ensure that `transit.releaseProxy(proxyId)` will be called.

#### Magic Values

*NOTE:* Make sure, the native function Ids are unique over time and for each JavaScript context. That includes a page reload!

## Scratchpad
Here are some (outdated) thoughts that otherwise would have been lost.
TBD: delete unneeded material and convert remaining parts into readable chunks :)

```

[arg[1] callWithArguments:@"some arg"]


arr[0][@"title"] == "doc's title"

f= (function(){transit.invokeNative("sdfsf", this, arguments)})

a.func = f;
a.func("asd");



_this.get("title") // _this.title
_this.eval("this.options.success(%@)", args: "some param")

_this.eval("__a(%@)", args: "some param")


[transit eval:@"2+%d" context:someProxy arguments:2]; -> // (2+2)


[_this eval:"%@.apply(%@)" arguments:arg[2], arg[1]]

// (function() { this.options.success(MAGIC) }).apply(transit.resolveProxy(...)))

// function(){(this.options.success("some param"))}.apply(transit.resolveProxy(…))



callNative(document)
 
callNative(function(){})

[transit eval:@"console.log=%@" arguments:callback];



Shared Life-Cycle with Sub Context

context = [transit createSubContext];

success = [context createFunc:^{
	[context destroy]
}];
error = [context createFunc:^{
	[context destroy]
}]

context = [transit subContextWithRelaseStrategy:ReleaseAllOnAnyCall];
success = [context createFunc:^{}];
error = [context createFunc:^{}];
completeCtx = [transit subContextWithRelaseStrategy:ReleaseAllOnAnyCall];

complete = [completeCtx createFunc:^{}];

successCtx = [completeCtx subCtx…]
success = [successCtx createFunc…]

weakContext = __weak(context)

success = [context createOneTimeFunc:^{
	weakContext…
}];
error = [context createFunc:^{
	weakContext…
}]


func = context funcWithBlock…
[context releaseFunc: func];



[transit eval:@"jQuery(document).ready(%@)" arguments:callback];
```
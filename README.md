

# Transit [![Build Status](https://travis-ci.org/BeamApp/Transit.png)](https://travis-ci.org/BeamApp/Transit) [![Cocoa Pod](http://cocoapod-badges.herokuapp.com/v/Transit/badge.png)](#)

Transit bridges between JavaScript and iOS, OSX, Android. You can easily embed a WebView or scripted logic via JS into your application and pass in native code as functions and especially event handlers. Whenever your native code got called you can use all arguments as well as the `this` argument even if they are JavaScript, functions again!

It does not rely on special JavaScript runtimes such as JavaScript Core or Rhino but can be used with any visual or non-visual component that understands JavaScript. That way, you can easily modify existing web pages to integrate with your native application (e.g. make `history.go(-1)` close the WebView or bind a button's `onClick` event to your native code). On the other hand, you can expose native functionality as accessible JavaScript functions (e.g. `[transit bind:<native code> toVariable:'navigator.vibrate']`).

## Example for Objective-C

Create a transit context from any (non-)visible webview

```
TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:someViewView];
```

Evaluate JavaScript with convenient placeholders `@` and implicit type conversion. So, calling

```
NSLog(@"%@", [context eval:@" {result: @ + Math.max(23, @) } " val: @"foo" val: @42.5]);
```
prints `NSDictionary: { result: "foo42.5" }` to the console.


You can store JavaScript functions in native variables and call them later or pass them back to JavaScript at any time. This code

```
TransitFunction *mathMax = [context eval:@"Math.max"];
NSLog(@"%@", [mathMax callWithArg:@3.5 arg:@6] );
NSLog(@"%@", [context eval:@" @(3.5, @)" val: mathMax val:@6] );
```
prints `6` in both cases.


But the real strength of transit comes when you combine native code with JavaScript. Blocks or delegates can be called from JavaScript and can even receive JavaScript functions as arguments. This code snippet

```
TransitFunction *applyFunc = [context functionWithBlock:^(TransitFunction* func, float a, int b){
  NSLog(@"arguments: func: %@, a: %f, b: %d", func, a, b);
  return [func callWithArg:@(a) arg:@(b)];
}];

NSNumber* result = [context eval:@"@(Math.max, 3.5, @)" val:applyFunc val:@6];
NSLog(@"result: %f", result.floatValue);
```

outputs

```
arguments: func: <TransitJSFunction: 0x11b34fc0>, a: 3.500000, b: 6
result: 6.0000
```

to the console.

There's a lot more. e.g. `TransitContext.currentCallScope` gives you access to the `this` variable, all `arguments` and let's you even print the unified call stack from JavaScript and native functions:

```
002 TransitNativeFunctionCallScope(this=<TransitUIWebViewContext: 0x75250d0>(<TransitJSFunction:0x11b34fc0>, 3.5, {field = 6;})
001 TransitEvalCallScope(this=<TransitUIWebViewContext: 0x75250d0>) @(Math.max, 3.5, {field:@}) -- values:(<TransitNativeFunction: 0x752ff00>, 6)

```

Read the [API documentation](http://cocoadocs.org/docsets/Transit/) for further details.


## Additional Information

You can find additional information in the Wiki, e.g.

 * [Internal Architecture](https://github.com/BeamApp/Transit/wiki/Internals)
 * [Android Internals](https://github.com/BeamApp/Transit/wiki/Android:-Communication)

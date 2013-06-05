

# Transit [![Build Status](https://travis-ci.org/BeamApp/Transit.png)](https://travis-ci.org/BeamApp/Transit) [![Cocoa Pod](http://cocoapod-badges.herokuapp.com/v/Transit/badge.png)](#)

Transit bridges between JavaScript and iOS, OSX, Android. You can easily embed a WebView or scripted logic via JS into your application and pass in native code as functions and especially event handlers. Whenever your native code got called you can use all arguments as well as the `this` argument even if they are JavaScript, functions again!

It does not rely on special JavaScript runtimes such as JavaScript Core or Rhino but can be used with any visual or non-visual component that understands JavaScript. That way, you can easily modify existing web pages to integrate with your native application (e.g. make `history.go(-1)` close the WebView or bind a button's `onClick` event to your native code). On the other hand, you can expose native functionality as accessible JavaScript functions (e.g. `[transit bind:<native code> toVariable:'navigator.vibrate']`).

## Example for Objective-C

This example creates a transit context from a webview and binds a native callback to `jQuery(document).ready`.

```
TransitContext* transit = [TransitContext transitContextWithWebView:someWebView];

TransitNativeFunc* callback = [transit functionWithBlock:^id(TransitNativeFunctionCallScope *scope) {
    // callscope offers access to .this, .arguments, callstack and more...
    NSLog(@"page %@ has been loaded", scope[@"title"]);
	
    // ...or use JS, again!
    NSString* url = [scope eval:@"this.location.href"];
    NSLog(@"page url: %@", url);
    return nil;
}];

[transit eval:@"jQuery(document).ready(@)" val:callback];
```

## Additional Information

You can find additional information in the Wiki, e.g.

 * [Internal Architecture](https://github.com/BeamApp/Transit/wiki/Internals)
 * [Android Internals](https://github.com/BeamApp/Transit/wiki/Android:-Communication)

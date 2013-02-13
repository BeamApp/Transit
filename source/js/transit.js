/*global Document Element */

(function(globalName){
    var transit = {
        retained:{},
        lastRetainId: 0,
        invocationQueue: [],
        invocationQueueMaxLen: 1000,
        handleInvocationQueueIsScheduled: false
    };

    var PREFIX_MAGIC_FUNCTION = "__TRANSIT_JS_FUNCTION_";
    var PREFIX_MAGIC_NATIVE_FUNCTION = "__TRANSIT_NATIVE_FUNCTION_";
    var PREFIX_MAGIC_OBJECT = "__TRANSIT_OBJECT_PROXY_";
    var MARKER_MAGIC_OBJECT_GLOBAL = "__TRANSIT_OBJECT_GLOBAL";
    var GLOBAL_OBJECT = window;

    transit.doInvokeNative = function(invocationDescription){
        throw "must be replaced by native runtime " + invocationDescription;
    };

    // should be replaced by native runtime to support more efficient solution
    // this behavior is expected:
    //   1. if one call throws an exception, all others must still be executed
    //   2. result is ignored
    //   3. order is not relevant
    transit.doHandleInvocationQueue = function(invocationDescriptions){
        for(var i=0; i<invocationDescriptions.length; i++) {
            var description = invocationDescriptions[i];
            try {
                transit.doInvokeNative(description);
            } catch(e) {
            }
        }
    };
    transit.doHandleInvocationQueue.isFallback = true;

    transit.asyncNativeFunction = function(nativeId) {
        var f = function(){
            transit.queueNative(nativeId, this, arguments);
        };
        f.transitNativeId = PREFIX_MAGIC_NATIVE_FUNCTION + nativeId;
        return f;
    };

    transit.nativeFunction = function(nativeId){
        var f = function(){
            return transit.invokeNative(nativeId, this, arguments);
        };
        f.transitNativeId = PREFIX_MAGIC_NATIVE_FUNCTION + nativeId;
        return f;
    };

    transit.recursivelyProxifyMissingFunctionProperties = function(missing, existing) {
        for(var key in existing) {
            if(existing.hasOwnProperty(key)) {
                var existingValue = existing[key];

                if(typeof existingValue === "function") {
                    missing[key] = transit.proxify(existingValue);
                }
                if(typeof existingValue === "object" && typeof missing[key] === "object" && missing[key] !== null) {
                    transit.recursivelyProxifyMissingFunctionProperties(missing[key], existingValue);
                }
            }
        }
    };

    transit.proxify = function(elem) {
        if(typeof elem === "function") {
            if(typeof elem.transitNativeId !== "undefined") {
                return elem.transitNativeId;
            } else {
                return transit.retainElement(elem);
            }
        }

        if(typeof elem === "object") {
            if(elem instanceof Document || elem instanceof Element) {
                return transit.retainElement(elem);
            }
            if(elem === GLOBAL_OBJECT) {
                return MARKER_MAGIC_OBJECT_GLOBAL;
            }

            var copy;
            try {
                copy = JSON.parse(JSON.stringify(elem));
            } catch (e) {
                return transit.retainElement(elem);
            }
            transit.recursivelyProxifyMissingFunctionProperties(copy, elem);
            return copy;
        }

        return elem;
    };

    transit.createInvocationDescription = function(nativeId, thisArg, args) {
        var invocationDescription = {
            nativeId: nativeId,
            thisArg: (thisArg === GLOBAL_OBJECT) ? null : transit.proxify(thisArg),
            args: []
        };

        for(var i = 0;i<args.length; i++) {
            invocationDescription.args.push(transit.proxify(args[i]));
        }

        return invocationDescription;
    };

    transit.invokeNative = function(nativeId, thisArg, args) {
        var invocationDescription = transit.createInvocationDescription(nativeId, thisArg, args);
        return transit.doInvokeNative(invocationDescription);
    };

    transit.handleInvocationQueue = function() {
        if(transit.handleInvocationQueueIsScheduled) {
            clearTimeout(transit.handleInvocationQueueIsScheduled);
            transit.handleInvocationQueueIsScheduled = false;
        }

        var copy = transit.invocationQueue;
        transit.invocationQueue = [];
        transit.doHandleInvocationQueue(copy);
    };

    transit.queueNative = function(nativeId, thisArg, args) {
        var invocationDescription = transit.createInvocationDescription(nativeId, thisArg, args);
        transit.invocationQueue.push(invocationDescription);
        if(transit.invocationQueue.length >= transit.invocationQueueMaxLen) {
            transit.handleInvocationQueue();
        } else {
            if(!transit.handleInvocationQueueIsScheduled) {
                transit.handleInvocationQueueIsScheduled = setTimeout(function(){
                    transit.handleInvocationQueueIsScheduled = false;
                    transit.handleInvocationQueue();
                }, 0);
            }
        }
    };

    transit.retainElement = function(element){
        transit.lastRetainId++;
        var id = "" + transit.lastRetainId;
        if(typeof element === "object") {
            id = PREFIX_MAGIC_OBJECT + id;
        }
        if(typeof element === "function") {
            id = PREFIX_MAGIC_FUNCTION + id;
        }

        transit.retained[id] = element;
        return id;
    };

    transit.r = function(retainId) {
        return transit.retained[retainId];
    };

    transit.releaseElementWithId = function(retainId) {
        if(typeof transit.retained[retainId] === "undefined") {
            throw "no retained element with Id " + retainId;
        }

        delete transit.retained[retainId];
    };

    window[globalName] = transit;

})("transit");
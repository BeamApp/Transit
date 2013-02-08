(function(){
    var transit = {
        retained:{},
        lastRetainId: 0
    };

    var PREFIX_MAGIC_FUNCTION = "__TRANSIT_JS_FUNCTION_";
    var PREFIX_MAGIC_NATIVE_FUNCTION = "__TRANSIT_NATIVE_FUNCTION_";
    var PREFIX_MAGIC_OBJECT = "__TRANSIT_OBJECT_PROXY_";

    var GLOBAL_OBJECT = window;

    transit.doInvokeNative = function(invocationDescription){
        throw "must be replaced by native runtime " + invocationDescription;
    };

    transit.nativeFunction = function(nativeId){
        var f = function(){
            transit.invokeNative(nativeId, this, arguments);
        };
        f.transitNativeId = nativeId;
        return f;
    };

    transit.proxifyMissingFunctionProperties = function(missing, existing) {
        for(var key in existing) {
            if(existing.hasOwnProperty(key)){
                var existingValue = existing[key];

                if(typeof existingValue === "function") {
                    missing[key] = transit.proxify(existingValue);
                }
                if(typeof existingValue === "object") {
                    transit.proxifyMissingFunctionProperties(missing[key], existingValue);
                }
            }
        }
    };

    transit.proxify = function(obj) {
        if(typeof obj === "function") {
            if(typeof obj.transitNativeId !== "undefined") {
                return PREFIX_MAGIC_NATIVE_FUNCTION + obj.transitNativeId;
            } else {
                return transit.retainElement(obj);
            }
        }

        if(typeof obj === "object") {
            try {
                var copy = JSON.parse(JSON.stringify(obj));
                transit.proxifyMissingFunctionProperties(copy, obj);
                return copy;
            } catch (e) {
                return transit.retainElement(obj);
            }
        }

        return obj;
    };

    transit.invokeNative = function(nativeId, thisArg, args) {
        var invocationDescription = {
            nativeId: nativeId,
            thisArg: (thisArg === GLOBAL_OBJECT) ? null : transit.proxify(thisArg),
            args: []
        };

        for(var i = 0;i<args.length; i++) {
            invocationDescription.args.push(transit.proxify(args[i]));
        }

        return transit.doInvokeNative(invocationDescription);
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

    transit.releaseElementWithId = function(retainId) {
        if(typeof transit.retained[retainId] === "undefined") {
            throw "no retained element with Id " + retainId;
        }

        delete transit.retained[retainId];
    };

    window.transit = transit;

})();
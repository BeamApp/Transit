(function(){
    var transit = {
        retained:{},
        lastRetainId: 0
    };

    var PREFIX_MAGIC_FUNCTION = "__TRANSIT_JS_FUNCTION_";
    var PREFIX_MAGIC_OBJECT = "__TRANSIT_OBJECT_PROXY_";

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
            return PREFIX_MAGIC_FUNCTION + transit.retainElement(obj);
        }

        if(typeof obj === "object") {
            try {
                var copy = JSON.parse(JSON.stringify(obj));
                transit.proxifyMissingFunctionProperties(copy, obj);
                return copy;
            } catch (e) {
                return PREFIX_MAGIC_OBJECT + transit.retainElement(obj);
            }
        }

        return obj;
    };

    transit.invokeNative = function(nativeId, thisArg, args) {
        var invocationDescription = {
            nativeId:nativeId,
            thisArg:transit.proxify(thisArg),
            args:[]};

        return transit.doInvokeNative(invocationDescription);
    };

    transit.retainElement = function(element){
        transit.retained[++transit.lastRetainId] = element;
        return ""+transit.lastRetainId;
    };

    transit.releaseElementWithId = function(retainId) {
        if(typeof transit.retained[retainId] === "undefined") {
            throw "no retained element with Id " + retainId;
        }

        delete transit.retained[retainId];
    };

    window.transit = transit;

})();
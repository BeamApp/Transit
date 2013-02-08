(function(){
    var transit = {};

    transit.requestCall = function(callRequest){
        throw "must be replaced by native runtime";
    };

    transit.nativeFunction = function(nativeId){
        var f = function(){
            transit.performCall(nativeId, this, arguments);
        };
        f.transitNativeId = nativeId;
        return f;
    };

    transit.performCall = function(nativeId, thisArg, otherArgs) {
        throw "to be implemented";
    };

    transit.retainProxy = function(element){
        throw "to be implemented";
    };

    transit.releaseProxy = function(proxyId) {
        throw "to be implemented";
    };

    window.transit = transit;

})();
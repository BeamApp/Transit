(function(globalName){
    var transit = window[globalName];

    var callCount = 0;
    transit.doInvokeNative = function(invocationDescription){
        invocationDescription.callNumber = ++callCount;
        transit.nativeInvokeTransferObject = invocationDescription;

        var iFrame = document.createElement('iframe');
        iFrame.setAttribute('src', 'transit:/doInvokeNative?c='+callCount);

        /* this call blocks until native code returns */
        /* native ccde reads from and writes to transit.nativeInvokeTransferObject */
        document.documentElement.appendChild(iFrame);

        /* free resources */
        iFrame.parentNode.removeChild(iFrame);
        iFrame = null;

        if(transit.nativeInvokeTransferObject === invocationDescription) {
            throw new Error("internal error with transit: invocation transfer object not filled.");
        }
        var result = transit.nativeInvokeTransferObject;
        if(result instanceof Error) {
            throw result;
        } else {
            return result;
        }
    };

    transit.doHandleInvocationQueue = function(invocationDescriptions) {
        callCount++;
        transit.nativeInvokeTransferObject = invocationDescriptions;
        var iFrame = document.createElement('iframe');
        iFrame.setAttribute('src', 'transit:/doHandleInvocationQueue?c='+callCount);

        document.documentElement.appendChild(iFrame);

        iFrame.parentNode.removeChild(iFrame);
        iFrame = null;
        transit.nativeInvokeTransferObject = null;
    };

})("transit");
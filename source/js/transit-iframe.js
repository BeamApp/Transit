(function(globalName){
    var transit = window[globalName];

    var callCount = 0;
    transit.doInvokeNative = function(invocationDescription){
        invocationDescription.callNumber = ++callCount;
        transit.nativeInvokeTransferObject = invocationDescription;

        var iFrame = document.createElement('iframe');
        iFrame.setAttribute('src', 'transit:'+callCount);

        /* this call blocks until native code returns */
        /* native ccde reads from and writes to transit.nativeInvokeTransferObject */
        document.documentElement.appendChild(iFrame);

        /* free resources */
        iFrame.parentNode.removeChild(iFrame);
        iFrame = null;

        return transit.nativeInvokeTransferObject;
    };

})("transit");
(function(globalName){
  var transit = window[globalName];
  var returnValue = null;

  function log() {
    console.log.apply(console, arguments);
  }

  function post(type, data) {
    if (data != null) {
      data = JSON.stringify({ data: data });
    }

    var result = prompt(type, data);

    try {
      result = JSON.parse(result);
    } catch (e) {
      return postException(e);
    }

    if (result == null) {
      log("Poll completed.");
      return;
    }

    if (result.type === "EXCEPTION") {
      throw(result.data);
    } else if (result.type === "EVAL") {
      returnValue = evaluateAndReturn(result.script, result.thisArg);
    } else if (result.type === "RETURN") {
      returnValue = eval(result.data);
    } else {
      throw("Unknown result type: " + result.type)
    }

    return returnValue;
  }

  function postException(e) {
    log("Exception: " + e);
    return post("__TRANSIT_MAGIC_EXCEPTION", transit.proxify(e.toString()));
  }

  function evaluateAndReturn(script, thisArgJs) {
    var result;
    var thisArg = eval(thisArgJs);

    try {
      result = (function() {
        __transit_args = arguments;
        return eval(script);
      }).apply(thisArg);
    } catch (e) {
      return postException(e);
    }

    // Eval seems to return `undefined` if prompt is called
    // so we look into the cached returnValue
    if ( typeof result === "undefined" ) {
      result = returnValue;
    }

    return post("__TRANSIT_MAGIC_RETURN", transit.proxify(result));
  }

  transit.doInvokeNative = function(invocationDescription) {
    return post("__TRANSIT_MAGIC_INVOKE", invocationDescription);
  };

  transit.poll = function() {
    return post("__TRANSIT_MAGIC_POLL");
  };

})(
  // TRANSIT_GLOBAL_NAME
    "transit"
  // TRANSIT_GLOBAL_NAME
);
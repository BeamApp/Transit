(function(globalName){
  var transit = window[globalName];
  var polling = false;
  var batch = false;

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
      if (polling) {
        log("Poll completed.");
        return;
      } else if (batch) {
        log("Batch completed.");
        return;
      } else {
        throw("Transit returned 'null', but didn't perform POLL or BATCH");
      }
    }

    if (result.type === "EXCEPTION") {
      throw(result.data);
    } else if (result.type === "EVAL") {
      return evaluateAndReturn(result.data);
    } else if (result.type === "RETURN") {
      return eval(result.data);
    } else {
      throw("Unknown result type: " + result.type)
    }
  }

  function postException(e) {
    log("Exception: " + e);
    return post("__TRANSIT_MAGIC_EXCEPTION", transit.proxify(e.toString()));
  }

  function evaluateAndReturn(script) {
    var result;

    try {
      console.log("Evaluating " + script.replace(/\s+/, " "));
      result = eval(script)
    } catch (e) {
      return postException(e);
    }

    console.log("Evaluating " + script.replace(/\s+/, " ") + " returned " + result);
    return post("__TRANSIT_MAGIC_RETURN", transit.proxify(result));
  }

  transit.doInvokeNative = function(invocationDescription) {
    return post("__TRANSIT_MAGIC_INVOKE", invocationDescription);
  };

  transit.doHandleInvocationQueue = function(invocationDescriptions) {
    batch = true;

    try {
      return post("__TRANSIT_MAGIC_BATCH_INVOKE", invocationDescriptions);
    } finally {
      batch = false;
    }
  };

  transit.poll = function() {
    polling = true;

    try {
      return post("__TRANSIT_MAGIC_POLL");
    } finally {
      polling = false;
    }
  };

})(
  // TRANSIT_GLOBAL_NAME
    "transit"
  // TRANSIT_GLOBAL_NAME
);
(function(globalName){
  var transit = window[globalName];

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

    // null is returned on __TRANSIT_MAGIC_POLL
    if (result != null) {
      switch(result.type) {
        case "EXCEPTION":
          throw(result.data);
        case "EVAL":
          evaluate(result.data);
          break;
        case "RETURN":
          return result.data;
        default:
          throw("Unknown result type: " + result.type)
      }
    }
  }

  function postException(e) {
    return post("__TRANSIT_MAGIC_EXCEPTION", transit.proxify(e.toString()));
  }

  function evaluate(script) {
    var result;

    try {
      result = eval(script);
    } catch (e) {
      return postException(e);
    }

    post("__TRANSIT_MAGIC_RETURN", transit.proxify(result));
  }

  transit.doInvokeNative = function(invocationDescription) {
    post("__TRANSIT_MAGIC_INVOKE", invocationDescription);
  };

  transit.poll = function() {
    post("__TRANSIT_MAGIC_POLL");
  };

})(
  // TRANSIT_GLOBAL_NAME
    "transit"
  // TRANSIT_GLOBAL_NAME
);
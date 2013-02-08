/*global jasmine, describe, it, xit, expect, beforeEach, afterEach, runs, waitsFor */
/*global transit */

describe("Transit", function() {
    it("exists", function(){
        expect(transit).toBeDefined();
    });

    describe("nativeFunction", function(){
        var _invokeNative = transit.invokeNative;
        beforeEach(function(){
            transit.invokeNative = jasmine.createSpy();
        });
        afterEach(function(){
            transit.invokeNative = _invokeNative;
        });

        it("attaches native attribute", function(){
            var f = transit.nativeFunction("someId");
            expect(typeof f).toEqual("function");
            expect(f.transitNativeId).toEqual("someId");
        });

        it("calls transit.performCall", function(){
            var f = transit.nativeFunction("someId");
            expect(transit.invokeNative).not.toHaveBeenCalled();
            f();
            expect(transit.invokeNative).toHaveBeenCalledWith("someId", window, []);

            var obj = {func:f};
            obj.func("foo");
            expect(transit.invokeNative).toHaveBeenCalledWith("someId", obj, ["foo"]);

            obj.func([1,2], "bar");
            expect(transit.invokeNative).toHaveBeenCalledWith("someId", obj, [[1,2], "bar"]);
        });
    });

    describe("retained", function(){
        afterEach(function(){
            // cleanup after messy tests
            transit.retained = {};
        });

        it("retains and releases elements", function(){
            expect(transit.retained).toEqual({});
            var obj = {};
            var id = transit.retainElement(obj);
            var expectedRetained = {};
            expectedRetained[id] = obj;
            expect(transit.retained).toEqual(expectedRetained);
            transit.releaseElementWithId(id);
            expect(transit.retained).toEqual({});
        });

        it("cannot release same id twice", function(){
           var id = transit.retainElement({});
           transit.releaseElementWithId(id);
           expect(function(){transit.releaseElementWithId(id);}).toThrow();
        });

        it("creates new ids for multiple retains", function(){
            var obj = {};
            var id1 = transit.retainElement(obj);
            var id2 = transit.retainElement(obj);
            expect(id1).not.toEqual(id2);
            expect(Object.getOwnPropertyNames(transit.retained)).toEqual([id1, id2]);
        });
    });

    describe("proxify", function(){
        var _undefined;
        var _bool = true;
        var _number = 42;
        var _string = "foobar";
        var _simpleArr = [1,2,3];
        //noinspection JSUnusedAssignment
        var _simpleObj = {_u:_undefined, _b:_bool, _n:_number, _s:_string, _sa:_simpleArr};
        var _function = function(){};

        afterEach(function(){
            // cleanup after messy tests
            transit.retained = {};
        });

        it("keeps identify for scalar values", function(){
            expect(transit.proxify(_undefined)).toBe(_undefined);
            expect(transit.proxify(_bool)).toBe(_bool);
            expect(transit.proxify(_number)).toBe(_number);
            expect(transit.proxify(_string)).toBe(_string);
        });

        it("returns equal objects if no functions", function(){
            expect(transit.proxify(_simpleArr)).toEqual(_simpleArr);
            expect(transit.proxify(_simpleObj)).toEqual(_simpleObj);
        });

        it("returns magic marker and retains functions", function(){
            var marker = transit.proxify(_function);

            expect(marker).toMatch(/^__TRANSIT_JS_FUNCTION_/);

            var expectedRetained = {};
            expectedRetained[marker] = _function;
            expect(transit.retained).toEqual(expectedRetained);
        });

        it("returns magic marker and retains complex object", function(){
            var o = {};
            o.cicle = o;

            var marker = transit.proxify(o);

            expect(marker).toMatch(/^__TRANSIT_OBJECT_PROXY_/);

            var expectedRetained = {};
            expectedRetained[marker] = o;
            expect(transit.retained).toEqual(expectedRetained);
        });

        it("replaces function properties with magic markers", function(){
            var obj = {func: _function, nested:{_b: _bool, func:_function}, _b:_bool, _n:_number, _s: _string};

            var actual = transit.proxify(obj);

            expect(Object.getOwnPropertyNames(actual)).toEqual(["nested", "_b", "_n", "_s", "func"]);
            expect(actual._b).toEqual(_bool);
            expect(actual._n).toEqual(_number);
            expect(actual._s).toEqual(_string);
            expect(actual.func).toMatch(/^__TRANSIT_JS_FUNCTION_/);

            expect(Object.getOwnPropertyNames(actual.nested)).toEqual(["_b", "func"]);
            expect(actual.nested._b).toEqual(_bool);
            expect(actual.nested.func).toMatch(/^__TRANSIT_JS_FUNCTION_/);
        });

        it("keeps order of function elements in array", function(){
            var f0 = function(){};
            var f1 = function(){};
            var f2 = function(){};

            var actual = transit.proxify([f0, f1, f2]);
            expect(actual.length).toEqual(3);
            expect(transit.retained[actual[0]]).toBe(f0);
            expect(transit.retained[actual[1]]).toBe(f1);
            expect(transit.retained[actual[2]]).toBe(f2);
        });

        it("recognizes native functions", function(){
            var nativeFunc = transit.nativeFunction("someId");
            var obj = {jsFunc:_function, nativeFunc: nativeFunc};
            var actual = transit.proxify(obj);
            expect(Object.getOwnPropertyNames(actual)).toEqual(["jsFunc", "nativeFunc"]);
            expect(transit.retained[actual.jsFunc]).toBe(_function);
            expect(actual.nativeFunc).toEqual("__TRANSIT_NATIVE_FUNCTION_someId");
        });

    });

    describe("invokeNative", function(){
        var _doInvokeNative = transit.doInvokeNative;
        beforeEach(function(){
            transit.doInvokeNative = jasmine.createSpy();
        });
        afterEach(function(){
            transit.doInvokeNative = _doInvokeNative;
        });

        it("calls doInvokeNative", function(){
            var simpleThisArg = {};
            transit.invokeNative("someId", simpleThisArg, []);
            expect(transit.doInvokeNative).toHaveBeenCalledWith({nativeId:"someId", thisArg:simpleThisArg, args:[]});
        });

    });
});
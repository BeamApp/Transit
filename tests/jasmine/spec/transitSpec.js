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
        afterEach(function(){
            // cleanup after messy tests
            transit.retained = {};
        });

        it("keeps identify for simple values", function(){
            var _undefined;
            var _bool = true;
            var _number = 42;
            var _string = "foobar";
            var _simpleArr = [1,2,3];
            var _simpleObj = {_u:_undefined, _b:_bool, _n:_number, _s:_string, _sa:_simpleArr};

            expect(transit.proxify(_undefined)).toBe(_undefined);
            expect(transit.proxify(_bool)).toBe(_bool);
            expect(transit.proxify(_number)).toBe(_number);
            expect(transit.proxify(_string)).toBe(_string);
            expect(transit.proxify(_simpleArr)).toBe(_simpleArr);
            expect(transit.proxify(_simpleObj)).toBe(_simpleObj);
        });

        it("returns magic marker and retains functions", function(){
            var f = function(){};
            var marker = transit.proxify(f);

            expect(marker).toMatch(/^__TRANSIT_JS_FUNCTION_/);

            var retainId = marker.match(/^__TRANSIT_JS_FUNCTION_(.*)/)[1];
            var expectedRetained = {};
            expectedRetained[retainId] = f;
            expect(transit.retained).toEqual(expectedRetained);
        });

        xit("returns magic marker and retains complex object", function(){
            var o = {};
            o.cicle = o;

            var marker = transit.proxify(o);

            expect(marker).toMatch(/^__TRANSIT_OBJECT_PROXY_/);

            var retainId = marker.match(/^__TRANSIT_OBJECT_PROXY_(.*)/)[1];
            var expectedRetained = {};
            expectedRetained[retainId] = o;
            expect(transit.retained).toEqual(expectedRetained);
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
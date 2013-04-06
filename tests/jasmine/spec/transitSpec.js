/*global jasmine, describe, it, xit, expect, beforeEach, afterEach, runs, waitsFor */
/*global transit */

describe("Transit", function() {
    it("exists", function(){
        expect(transit).toBeDefined();
    });

    describe("nativeFunction", function(){
        describe("blocked", function(){
            var _invokeNative = transit.invokeNative;
            beforeEach(function(){
                transit.invokeNative = jasmine.createSpy("invokeNative");
            });
            afterEach(function(){
                transit.invokeNative = _invokeNative;
            });

            it("attaches native attribute", function(){
                var f = transit.nativeFunction("someId");
                expect(typeof f).toEqual("function");
                expect(f.transitNativeId).toEqual("__TRANSIT_NATIVE_FUNCTION_someId");
            });

            it("calls transit.invokeNative", function(){
                var f = transit.nativeFunction("someId");
                expect(transit.invokeNative).not.toHaveBeenCalled();
                f();
                expect(transit.invokeNative).toHaveBeenCalledWith("someId-intentionallyWrong", window, [], undefined);

                var obj = {func:f};
                obj.func("foo");
                expect(transit.invokeNative).toHaveBeenCalledWith("someId", obj, ["foo"], undefined);

                obj.func([1,2], "bar");
                expect(transit.invokeNative).toHaveBeenCalledWith("someId", obj, [[1,2], "bar"], undefined);

                f.transitNoThis = true;
                obj.func([1,2], "bar");
                expect(transit.invokeNative).toHaveBeenCalledWith("someId", obj, [[1,2], "bar"], true);
            });

            it("uses result of transit.invokeNative", function(){
                transit.invokeNative = transit.invokeNative.andReturn(3);

                var f = transit.nativeFunction("someId");
                expect(transit.invokeNative).not.toHaveBeenCalled();
                var result = f(1,2);
                expect(transit.invokeNative).toHaveBeenCalledWith("someId", window, [1,2], undefined);
                expect(result).toEqual(3);
            });
        });

        describe("async", function(){
            var _queueNative = transit.queueNative;

            beforeEach(function(){
                transit.queueNative = jasmine.createSpy("queueNative");
            });
            afterEach(function(){
                transit.queueNative = _queueNative;
            });

            it("attaches native attribute", function(){
                var f = transit.nativeFunction("someId", {async:true});
                expect(typeof f).toEqual("function");
                expect(f.transitNativeId).toEqual("__TRANSIT_NATIVE_FUNCTION_someId");
            });

            it("calls transit.queueNative", function(){
                var f = transit.nativeFunction("someId", {async:true});
                expect(transit.queueNative).not.toHaveBeenCalled();
                f();
                expect(transit.queueNative).toHaveBeenCalledWith("someId", window, [], undefined);

                var obj = {func:f};
                obj.func("foo");
                expect(transit.queueNative).toHaveBeenCalledWith("someId", obj, ["foo"], undefined);

                obj.func([1,2], "bar");
                expect(transit.queueNative).toHaveBeenCalledWith("someId", obj, [[1,2], "bar"], undefined);

                f.transitNoThis = true;
                obj.func([1,2], "bar");
                expect(transit.queueNative).toHaveBeenCalledWith("someId", obj, [[1,2], "bar"], true);
            });

        });

        describe("noThis", function(){
            it("omits noThis attribute on default", function(){
                var f = transit.nativeFunction("someId");
                expect(typeof f).toEqual("function");
                expect(f.transitNoThis).toBeFalsy();
            });
            it("attraches noThis attribute if specified", function(){
                var f = transit.nativeFunction("someId", {noThis:true});
                expect(typeof f).toEqual("function");
                expect(f.transitNoThis).toBeTruthy();
            });

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

        it("provides access to retained via r function", function(){
            var id = transit.retainElement({});
            expect(transit.r(id)).toBe(transit.retained[id]);
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
            o.cycle = o;

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

        it("keeps order of function in array of nested object", function(){
            var f0 = function(){};
            var f1 = function(){};
            var f2 = function(){};
            var obj = {funcs: [f0 , f1, f2]};

            var actual = transit.proxify(obj);
            expect(actual.funcs.length).toEqual(3);
            expect(Object.getOwnPropertyNames(actual)).toEqual(["funcs"]);
            expect(transit.retained[actual.funcs[0]]).toBe(f0);
            expect(transit.retained[actual.funcs[1]]).toBe(f1);
            expect(transit.retained[actual.funcs[2]]).toBe(f2);
        });

        it("recognizes native functions", function(){
            var nativeFunc = transit.nativeFunction("someId");
            var obj = {jsFunc:_function, nativeFunc: nativeFunc};
            var actual = transit.proxify(obj);
            expect(Object.getOwnPropertyNames(actual)).toEqual(["jsFunc", "nativeFunc"]);
            expect(transit.retained[actual.jsFunc]).toBe(_function);
            expect(actual.nativeFunc).toEqual("__TRANSIT_NATIVE_FUNCTION_someId");
        });

        it("recognizes document as complex element", function(){
            expect(transit.proxify(document)).toEqual(jasmine.any(String));
        });

        it("recognizes document.body as complex element", function(){
            expect(transit.proxify(document.body)).toEqual(jasmine.any(String));
        });

        it("uses magic marker for global object", function(){
            expect(transit.proxify(window)).toEqual("__TRANSIT_OBJECT_GLOBAL");
        });

        it("creates proxy if global object in nested properties", function(){
            expect(transit.proxify([window, window])).toEqual(jasmine.any(String));
        });

        it("keeps null", function(){
            expect(transit.proxify(null)).toBeNull();
        });

        it("creates a proxy if it is not a direct object", function(){
            function Test() {}

            var object = new Test();
            expect(transit.proxify(object)).toEqual(jasmine.any(String));
        });
    });

    describe("createInvocationDescription", function(){
        it("keeps simple thisArg", function(){
            var simpleObj = {a:"1"};
            var desc = transit.createInvocationDescription("someId", simpleObj, []);
            expect(desc).toEqual({
                nativeId:"someId",
                thisArg:simpleObj,
                args:[]
            });
        });

        it("omits thisArg of asked for it", function(){
            var simpleObj = {a:"1"};
            var desc = transit.createInvocationDescription("someId", simpleObj, [], true);
            expect(desc).toEqual({
                nativeId:"someId",
                thisArg:null,
                args:[]
            });
        });

        it("treats global object as null for thisArg", function(){
            var desc = transit.createInvocationDescription("someId", window, []);
            expect(desc).toEqual({
                nativeId: "someId",
                thisArg: null,
                args: []
            });
        });

        it("proxifies arguments and this if complex", function(){
            var simpleObj = {a:"1"};
            var complexObj = document;
            var desc = transit.createInvocationDescription("someId", complexObj, [1, simpleObj, complexObj]);
            expect(desc).toEqual({
                nativeId: "someId",
                thisArg: jasmine.any(String),
                args: [1, simpleObj, jasmine.any(String)]
            });
        });

    });


    describe("invokeNative and queueNative", function(){
        var _doInvokeNative = transit.doInvokeNative;
        var _createInvocationDescription = transit.createInvocationDescription;
        var _doHandleInvocatenQueue = transit.doHandleInvocationQueue;
        var _invocationQueueMaxLen = transit.invocationQueueMaxLen;
        var _fakeInvocationDescription = "myDecription";

        beforeEach(function(){
            transit.doInvokeNative = jasmine.createSpy("doInvokeNative");
            transit.createInvocationDescription = jasmine.createSpy("createInvocationDescription").andReturn(_fakeInvocationDescription);
            transit.doHandleInvocationQueue = jasmine.createSpy("doHandleInvocationQueue");
            transit.invocationQueue = [];
        });
        afterEach(function(){
            transit.invocationQueue = [];
            transit.handleInvocationQueue();
            transit.doInvokeNative = _doInvokeNative;
            transit.createInvocationDescription = _createInvocationDescription;
            transit.doHandleInvocationQueue = _doHandleInvocatenQueue;
            transit.invocationQueueMaxLen = _invocationQueueMaxLen;

        });

        describe("invokeNative", function(){
            it("calls doInvokeNative with description from createInvocationDescription", function(){
                transit.invokeNative(1,2,3,true);
                expect(transit.createInvocationDescription).toHaveBeenCalledWith(1,2,3, true);
                expect(transit.doInvokeNative).toHaveBeenCalledWith(_fakeInvocationDescription);

                expect(transit.createInvocationDescription.callCount).toEqual(1);
                expect(transit.doInvokeNative.callCount).toEqual(1);
            });
        });

        describe("queueNative", function(){
            it("calls createInvocationDescription and adds to queue", function(){
                runs(function(){
                    expect(transit.handleInvocationQueueIsScheduled).toBeFalsy();

                    transit.queueNative(1,2,3);
                    expect(transit.createInvocationDescription).toHaveBeenCalledWith(1,2,3);
                    expect(transit.handleInvocationQueueIsScheduled).toBeTruthy();

                    transit.queueNative(4,5,6);
                    expect(transit.createInvocationDescription).toHaveBeenCalledWith(4,5,6);

                    expect(transit.createInvocationDescription.callCount).toEqual(2);
                    expect(transit.doInvokeNative.callCount).toEqual(0);
                    expect(transit.invocationQueue).toEqual([_fakeInvocationDescription, _fakeInvocationDescription]);

                    // handleInvocationQueue shoule be called asynchronous
                    expect(transit.doHandleInvocationQueue.callCount).toEqual(0);
                });
                waitsFor(function(){
                    return transit.doHandleInvocationQueue.callCount > 0;
                });
                runs(function(){
                    expect(transit.doHandleInvocationQueue).toHaveBeenCalledWith([_fakeInvocationDescription, _fakeInvocationDescription]);
                    expect(transit.invocationQueue).toEqual([]);
                    expect(transit.handleInvocationQueueIsScheduled).toBeFalsy();
                });
            });

            it("works fine with explicit calls of handleInvocationQueue", function(){
                expect(transit.handleInvocationQueueIsScheduled).toBeFalsy();

                transit.queueNative(1,2,3);
                expect(transit.createInvocationDescription).toHaveBeenCalledWith(1,2,3);
                expect(transit.handleInvocationQueueIsScheduled).toBeTruthy();

                transit.queueNative(4,5,6);
                expect(transit.createInvocationDescription).toHaveBeenCalledWith(4,5,6);

                expect(transit.createInvocationDescription.callCount).toEqual(2);
                expect(transit.doInvokeNative.callCount).toEqual(0);
                expect(transit.invocationQueue).toEqual([_fakeInvocationDescription, _fakeInvocationDescription]);

                expect(transit.doHandleInvocationQueue.callCount).toEqual(0);

                // now, call handleInvocationQueue synced!
                transit.handleInvocationQueue();
                expect(transit.doHandleInvocationQueue).toHaveBeenCalledWith([_fakeInvocationDescription, _fakeInvocationDescription]);
                expect(transit.invocationQueue).toEqual([]);
                expect(transit.handleInvocationQueueIsScheduled).toBeFalsy();
            });

            it("it respects invocationQueueMaxLen", function(){
                transit.invocationQueueMaxLen = 2;
                expect(transit.handleInvocationQueueIsScheduled).toBeFalsy();

                transit.queueNative(1,1,1);
                expect(transit.invocationQueue).toEqual([_fakeInvocationDescription]);
                expect(transit.handleInvocationQueueIsScheduled).toBeTruthy();
                expect(transit.doHandleInvocationQueue.callCount).toEqual(0);

                transit.queueNative(2,2,2);
                expect(transit.invocationQueue).toEqual([]);
                expect(transit.handleInvocationQueueIsScheduled).toBeFalsy();
                expect(transit.doHandleInvocationQueue.callCount).toEqual(1);
                expect(transit.doHandleInvocationQueue).toHaveBeenCalledWith([_fakeInvocationDescription, _fakeInvocationDescription]);

                transit.queueNative(3,3,3);
                expect(transit.invocationQueue).toEqual([_fakeInvocationDescription]);
                expect(transit.handleInvocationQueueIsScheduled).toBeTruthy();
                expect(transit.doHandleInvocationQueue.callCount).toEqual(1);

                transit.queueNative(4,4,4);
                expect(transit.invocationQueue).toEqual([]);
                expect(transit.handleInvocationQueueIsScheduled).toBeFalsy();
                expect(transit.doHandleInvocationQueue.callCount).toEqual(2);
                expect(transit.doHandleInvocationQueue).toHaveBeenCalledWith([_fakeInvocationDescription, _fakeInvocationDescription]);
            });
        });

    });

    describe("doHandleInvocationQueue", function(){
        // if test suite is running with replaced implementation, skip these tests
        if(!transit.doHandleInvocationQueue.isFallback) {
            return;
        }

        var _doInvokeNative = transit.doInvokeNative;

        beforeEach(function(){
            transit.doInvokeNative = jasmine.createSpy("doInvokeNative").andCallFake(function(a){
                if(a === 3) {
                    throw "exception from fake transit.doInvokeNative";
                }
            });
        });

        afterEach(function(){
            transit.doInvokeNative = _doInvokeNative;
        });

        it("calls doInvokeNative", function(){
            transit.doHandleInvocationQueue([1,2]);
            expect(transit.doInvokeNative.callCount).toEqual(2);
            expect(transit.doInvokeNative).toHaveBeenCalledWith(1);
            expect(transit.doInvokeNative).toHaveBeenCalledWith(2);
        });

        it("calls recovers on exceptions", function(){
            transit.doHandleInvocationQueue([1,2,3,4]);
            expect(transit.doInvokeNative.callCount).toEqual(4);
            expect(transit.doInvokeNative).toHaveBeenCalledWith(1);
            expect(transit.doInvokeNative).toHaveBeenCalledWith(2);
            expect(transit.doInvokeNative).toHaveBeenCalledWith(3);
            expect(transit.doInvokeNative).toHaveBeenCalledWith(4);
        });

    });
});
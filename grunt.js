/*global module:false */

module.exports = function(grunt) {

    grunt.loadNpmTasks('grunt-jasmine-task');
    grunt.loadNpmTasks('grunt-text-replace');

    grunt.initConfig({
        lint: {
            // js/js.* only contains coffee files
            files: ['grunt.js', 'source/js/*.js', 'tests/jasmine/spec/*.js']
        },
        jasmine: {
            all: {
                src: 'tests/jasmine/SpecRunner.html',
                errorReporting: true
            }
        },
        replace: {
            embedTransitIntoObjC: {
                src: "source/objc/TransitCore.m",
                overwrite: true,
                replacements:[{
                    from: /\/\/ _TRANSIT_JS_RUNTIME_CODE_START[\s\S]*\/\/ _TRANSIT_JS_RUNTIME_CODE_END/,
                    to:function(){
                        var js = "(function(){";
                        js += grunt.file.read("source/js/transit.js");
                        js += grunt.file.read("source/js/transit-iframe.js");
                        js += "})()";


                        var replacement = "// _TRANSIT_JS_RUNTIME_CODE_START\n    ";
                        replacement += JSON.stringify(js);
                        replacement += "\n    // _TRANSIT_JS_RUNTIME_CODE_END";
                        return replacement;
                    }
                }]
            }

        },
        watch: {
            files: ['grunt.js', 'source/**/*.js', 'tests/**/*.js', 'tests/**/*.html'],
            tasks: ['continuous']
        },
        jshint: {
            options: {
                curly: true,
                eqeqeq: true,
                immed: true,
                latedef: true,
                newcap: true,
                noarg: true,
                sub: true,
                undef: true,
                boss: true,
                eqnull: true,
                browser: true
            },
            globals: {
                jQuery: true
            }
        }
    });

// Default task.
    grunt.registerTask('default', 'continuous watch');
    grunt.registerTask('travis', 'lint jasmine');
    grunt.registerTask('continuous', 'lint jasmine replace');
};

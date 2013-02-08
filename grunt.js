/*global module:false */

module.exports = function(grunt) {

    grunt.loadNpmTasks('grunt-jasmine-task');

    grunt.initConfig({
        lint: {
            // js/js.* only contains coffee files
            files: ['source/js/*.js', 'tests/jasmine/spec/*.js']
        },
        jasmine: {
            all: {
                src: 'tests/jasmine/SpecRunner.html',
                errorReporting: true
            }
        },

        watch: {
            files: ['source/**/*.js', 'tests/**/*.js', 'tests/**/*.html'],
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
    grunt.registerTask('continuous', 'lint jasmine');
};

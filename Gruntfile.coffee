module.exports = (grunt) ->

  grunt.initConfig
    mochaTest:
      test:
        options:
          ui: 'bdd'
          reporter: 'spec'
          require: ['coffee-script']
          slow: '1ms'

        src: ['test/**/*.coffee']

    watch:
      tests:
        files: ['test/**/*.coffee', 'lib/**/*.coffee']
        tasks: ['mochaTest']


  grunt.loadNpmTasks('grunt-mocha-test')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.registerTask('test', ['mochaTest', 'watch'])

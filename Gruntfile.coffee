module.exports = (grunt) ->

  grunt.initConfig
    mochacli:
      test:
        options:
          ui: 'bdd'
          reporter: 'spec'
          compilers: ['coffee:coffee-script/register']
          slow: '1ms'
          timeout: '10s'
          files: 'test/**/*'

    watch:
      tests:
        files: ['test/**/*.coffee', 'lib/**/*.coffee']
        tasks: ['mochacli']


  grunt.loadNpmTasks('grunt-mocha-cli')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.registerTask('test', ['mochacli', 'watch'])

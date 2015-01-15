module.exports = (grunt) ->

  grunt.initConfig

    coffee:
      options:
        bare: true
      compile:
        files: [
          expand: true
          cwd: "./lib"
          src: ["**/*.coffee"]
          dest: "./lib"
          ext: ".js"
        ]

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
        tasks: ['coffee', 'mochacli']


  grunt.loadNpmTasks('grunt-mocha-cli')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')

  grunt.registerTask('test', ['coffee', 'mochacli'])
  grunt.registerTask('default', ['test', 'watch'])

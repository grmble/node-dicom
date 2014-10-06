path = require 'path'

srcDir = 'src'
dstDir = 'lib'
tstDir = 'test'

module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-nodeunit'


  grunt.initConfig
    watch:
      coffee:
        files: "#{srcDir}/**/*.coffee"
        tasks: ['coffee:watched', 'nodeunit']
        options:
          spawn: false

    coffee:
      compile:
        expand: true,
        cwd: "#{srcDir}/",
        src: ['**/*.coffee'],
        dest: "#{dstDir}/",
        ext: '.js'
      watched:
        expand: true,
        cwd: "#{srcDir}/",
        src: ['**/*.coffee'],
        dest: "#{dstDir}/",
        ext: '.js'

    nodeunit:
      all: ["#{tstDir}/test_*.coffee"]

  grunt.event.on 'watch', (action, filepath) ->
    coffeeConfig = grunt.config "coffee"
    coffeeConfig.watched.src = path.relative(srcDir, filepath)
    grunt.config "coffee", coffeeConfig

  grunt.registerTask 'default', ['coffee', 'nodeunit', 'watch']
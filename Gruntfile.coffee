path = require 'path'

srcDir = 'src'
dstDir = 'lib'
tstDir = 'test'

sourceMap = false

srcRe = new RegExp "^#{srcDir}/"

module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-nodeunit'


  grunt.initConfig
    watch:
      coffee:
        files: ["#{srcDir}/**/*.coffee", "#{tstDir}/test_*.coffee"]
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
        options:
          sourceMap: sourceMap
      watched:
        expand: true,
        cwd: "#{srcDir}/",
        src: ['**/*.coffee'],
        dest: "#{dstDir}/",
        ext: '.js'
        options:
          sourceMap: sourceMap

    nodeunit:
      all: ["#{tstDir}/test_*.coffee"]

  grunt.event.on 'watch', (action, filepath) ->
    if srcRe.test filepath
      coffeeConfig = grunt.config "coffee"
      coffeeConfig.watched.src = path.relative(srcDir, filepath)
      grunt.config "coffee", coffeeConfig
    else
      coffeeConfig = grunt.config "coffee"
      coffeeConfig.watched.src = []
      grunt.config "coffee", coffeeConfig


  grunt.registerTask 'default', ['coffee', 'nodeunit', 'watch']
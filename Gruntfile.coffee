path = require 'path'

module.exports = (grunt) ->
    # Project configuration
    grunt.initConfig
        pkg: grunt.file.readJSON('package.json')
        sass:
            dev:
                files:
                    'public/css/main.css': 'sass/main.scss'
        coffee:
            dev:
                files: [
                    {
                        expand: true
                        cwd: 'coffee/'
                        src: ['**/*.coffee']
                        dest: ''
                        ext: '.js'
                    }
                ]
        express:
            custom:
                options:
                    bases: 'www-root'
                    port: process.env.PORT || 3000
                    server: path.resolve('./app')
        watch:
            sass:
                files: ['sass/*.scss']
                tasks: ['sass']
            server:
                files: ['coffee/**/*.coffee']
                tasks: ['coffee', 'express', 'express-keepalive']
                options:
                    nospawn: true
                    interrupt: true

    taskList = ['grunt-sass', 'grunt-contrib-coffee', 'grunt-contrib-watch', 'grunt-express']
    grunt.loadNpmTasks tasks for tasks in taskList

    grunt.registerTask 'default', ['watch']
    # Post-receive build task to be executed on heroku node
    grunt.registerTask 'heroku', ['sass', 'coffee']

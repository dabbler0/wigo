gulp = require 'gulp'
gutil = require 'gulp-util'
browserify = require 'browserify'
coffeeify = require 'caching-coffeeify'
uglify = require 'gulp-uglify'
transform = require 'vinyl-transform'
rename = require 'gulp-rename'
coffee = require 'gulp-coffee'

gulp.task 'browser', ->
  browserified = transform (filename) ->
    b = browserify(filename, standalone: 'wigo')
    b.transform(coffeeify)
    return b.bundle()
  gulp.src('src/browser.coffee')
      .pipe(browserified)
      #.pipe(uglify())
      .pipe(rename 'browser.js')
      .pipe(gulp.dest './build/')

gulp.task 'demo', ->
  gulp.src('demo/src/demo.coffee')
      .pipe(coffee().on('error', gutil.log))
      .pipe(gulp.dest './demo/js/')

gulp.task 'default', ['browser', 'demo']

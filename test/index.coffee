should = require 'should'
path = require 'path'
assert = require 'stream-assert'
gulp = require 'gulp'
deamdify = require '../'
require 'mocha'

describe 'gulp-deamdify', () ->
  it('Should not to stream any file, if no one goes in', (done) -> 
    gulp.src []
      .pipe deamdify()
      .pipe assert.length 0
      .pipe assert.end done
  )

  it('Should deamdfy only one file if it is a require call', (done) -> 
    gulp.src './test/fixtures/without-defines/*.js'
      .pipe deamdify()
      .pipe assert.length 1
      .pipe assert.end done
  )
  it('Should take path from latest file', (done) ->
    gulp.src './test/fixtures/with-defines/*.js'
      .pipe deamdify()
      .pipe assert.length 1
      .pipe assert.first (file) ->
        given = path.resolve file.path
        expected = path.resolve path.join """#{__dirname}/fixtures/with-defines/main.js"""
        given.should.equal expected
      .pipe assert.end done
  )
path = require 'path'
fs = require 'fs'
async = require 'async'

fileModifiedTime = (filepath, cb) ->
  fs.stat filepath, (err, data) ->
    return cb(err, data) if err
    cb(err, data.mtime)

composite = require '../src/composite.coffee'

describe 'composite', ->
  dir = process.cwd()
  ojCoffeeFile = path.join dir, 'src/composite.coffee'
  ojJSFile = path.join dir, 'src/composite.js'

  it 'should be up-to-date with the .coffee file (run \'cake build\')', (done) ->
    async.parallel
      coffee: ((cb) -> fileModifiedTime ojCoffeeFile, cb),
      js: ((cb)-> fileModifiedTime ojJSFile, cb)
      , (err, times) ->
        throw err if err
        assert times.coffee.getTime() <= times.js.getTime(), 'coffee script file is out of date'
        done()

  it 'should have the same version as package.json', (done) ->
    assert composite.version, 'composite.version does not exist'

    # Read package.json
    fs.readFile path.join(dir, 'package.json'), 'utf8', (err, data) ->
      throw err if err
      json = JSON.parse(data)
      assert json.version, 'package.json does not have a version (or couldn\'t be parsed)'
      composite.version.should.equal json.version
      done()

  it 'should be a function', ->
    composite.should.be.an 'function'

  it 'should have a version equal to the package.json', ->
    expect(composite.version).to.be.a 'string'

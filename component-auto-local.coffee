fs = require 'fs'
path = require 'path'
async = require 'async'
debug = require('debug')('component-auto-local')


ComponentJson = null
localDirs = []

removeNotExist = ()->
  for loDir, inx in ComponentJson.locals
    unless loDir in localDirs
      ComponentJson.locals[inx] = null

appendNew = ()->
  for loDir in localDirs  
    unless loDir in ComponentJson.locals
      ComponentJson.locals.push loDir

cleansingLocals = ()->
  ComponentJson.locals = ComponentJson.locals.filter (item)-> return  item != null

saveJson = (jsonPath, cb)->
  fs.writeFile jsonPath, JSON.stringify(ComponentJson, null, 2), cb


getSubDirs = (dir, callback)->
  fs.readdir dir, (err, paths)->
    return callback err if err
    # debug 'result = ', paths
    # files.map (file)-> return path.join dir, file
    async.filter paths, (pathname, callback)-> 
      relPath = path.join dir, pathname 
      fs.stat relPath, (err, stats)->
        callback stats.isDirectory()
    , (result)->
      # debug 'result = ', result
      callback null, result

auto = ( done)->
  jsonPath = auto.option.componentJson
  # json = require './' + file
  fs.readFile jsonPath, (err, data)->
    return done(err) if err
    try
      ComponentJson = JSON.parse(data);
      ComponentJson.locals = [] unless ComponentJson.locals 
      debug 'original local =', ComponentJson.locals 
      if ComponentJson.paths
        async.map ComponentJson.paths, getSubDirs, (err, result)-> 
          # debug 'result = ', result
          return done err if err
          localDirs = result.reduce (a, b) ->  a.concat(b)
          localDirs = localDirs.filter (item)-> 
            return item[0] isnt auto.option.ignorePrefix 
          debug 'found local dirs =', localDirs 

          removeNotExist()
          cleansingLocals()
          debug 'after removing not exist local =',  ComponentJson.locals 

          appendNew()
          debug 'after appending new local =',  ComponentJson.locals 
          saveJson jsonPath, (err)->
            debug 'save `component.json`'
            done(err)


    catch err
      return done(err)

auto.option =  
  ignorePrefix: '!'
  componentJson : './component.json'




module.exports = auto
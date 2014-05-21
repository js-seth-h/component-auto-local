fs = require 'fs'
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

auto = (jsonPath, done)->
  # json = require './' + file
  fs.readFile jsonPath, (err, data)->
    return done(err) if err
    try
      ComponentJson = JSON.parse(data);
      ComponentJson.locals = [] unless ComponentJson.locals 
      if ComponentJson.paths
        async.map ComponentJson.paths, fs.readdir, (err, result)->
          debug 'err', err
          localDirs = result.reduce (a, b) ->  a.concat(b)
          debug 'localDirs ', localDirs 

          removeNotExist()
          appendNew()
          cleansingLocals()
          saveJson jsonPath, (err)->
            done(err)


    catch err
      return done(err)



module.exports = auto
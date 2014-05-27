fs = require 'fs'
path = require 'path'
async = require 'async'
debug = require('debug')('component-auto-local')
glob = require 'glob'
ho = require 'handover'
 
# ComponentJson = null
# localDirs = []

saveJson = (jsonPath, cb)->
  fs.writeFile jsonPath, JSON.stringify(ctx.ComponentJson, null, 2), cb


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


auto2 = ( done)->
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
 

loadJson = (done)-> 
  jsonPath = auto.option.componentJson
  fs.readFile jsonPath, (err, data)->
    return done(err) if err
    try
      ctx.ComponentJson = JSON.parse(data); 
      done(null)
    catch err
      return done(err)


spreadDependancy = (done)->
  debug 'ctx = ', ctx

  for dir in ctx.localDirs
    componentJsonPath = path.join dir, 'Component.json'
    fs.readFile componentJsonPath, (err, data)->
      return done(err) if err
      try
        json = JSON.parse(data);
        json.dependencies = ctx.ComponentJson.dependencies

  done()

loadJson = (jsonPath , next)-> 
  # jsonPath = auto.option.componentJson
  fs.readFile jsonPath, (err, data)->
    return next err if err
    try
      err = null
      json = JSON.parse(data);
    catch err
      # return next err

    next err, json

retriveLocals = (ctx, next)-> 
  getLocalComponents = (dir, callback)->
    jsonPattern = path.join dir, "*/Component.json"
    glob jsonPattern, (err, files)->
      debug 'glob', err, files
      files = files.map (file)->
        return  path.dirname file
      callback null, files
  debug 'paths = ', ctx.RootJson.paths 
  async.map ctx.RootJson.paths, getLocalComponents, (err, result)-> 
    return next err if err
    localDirs = result.reduce (a, b) ->  a.concat(b)
    ctx.localDirs = localDirs.filter (item)-> 
      name = path.basename item
      return name[0] isnt auto.option.ignorePrefix 
    debug 'found local dirs =', ctx.localDirs 
    ctx.locals = ctx.localDirs.map (item)-> return path.basename item
    debug 'found locals =', ctx.locals
    next(null)


loadRootJson = (ctx, next)->
  loadJson auto.option.componentJson, (err, json)->
    ctx.RootJson = json
    next()
retriveLocalsJon = (ctx, next)-> 
  getLocalComponents = (dir, callback)->
    jsonPattern = path.join dir, "*/Component.json"
    glob jsonPattern, callback
  debug 'paths = ', ctx.RootJson.paths 
  async.map ctx.RootJson.paths, getLocalComponents, (err, result)-> 
    # debug 'localjson ' , err, result
    return next err if err
    localDirs = result.reduce (a, b) ->  a.concat(b)
    ctx.localJsonPath = localDirs.filter (item)-> 
      name = path.basename path.dirname item
      return name[0] isnt auto.option.ignorePrefix 
    debug 'found localJsonPath =', ctx.localJsonPath 
    next()
loadLocalJson = (ctx, next)->
  # f = ho [ loadJson ]
  # contexts = ctx.localJsonPath.map (el)-> return {path : el}
  # f.parallel contexts, (err, results)->
  async.map ctx.localJsonPath, loadJson, (err, results)->
    debug 'loadLocalJson', err, results
    ctx.json = {}
    ctx.locals = []
    results.map (item, inx)->
      pathname = ctx.localJsonPath[inx]
      ctx.json[pathname] = item
      ctx.locals.push item.name
    next()



updateLocals = (ctx, done)-> 

  removeNotExist = ()->
    for loDir, inx in ctx.RootJson.locals
      unless loDir in ctx.locals
        ctx.RootJson.locals[inx] = null

  appendNew = ()->
    for loDir in ctx.locals  
      unless loDir in ctx.RootJson.locals
        ctx.RootJson.locals.push loDir

  cleansingLocals = ()->
    ctx.RootJson.locals = ctx.RootJson.locals.filter (item)-> return  item != null

  ctx.RootJson.locals = [] unless ctx.RootJson.locals 
  debug 'original local =', ctx.RootJson.locals

  removeNotExist()
  cleansingLocals()
  debug 'after removing not exist local =',  ctx.RootJson.locals 
  appendNew()
  debug 'after appending new local =',  ctx.RootJson.locals 
  # jsonPath = auto.option.componentJson
  done()
  # saveJson jsonPath, (err)->
  #   debug 'save `component.json`'
  #   done(err)

spreadDependancy = (ctx, next)->
  debug 'spreadDependancy'

  for own key, value of ctx.json
    value.dependencies = ctx.RootJson.dependencies
    name = value.name
    paths = []
    localDir = path.dirname key
    for own key2, v of ctx.json
      otherDir = path.dirname key2
      continue if localDir is otherDir
      rel = path.relative localDir, otherDir
      rel = rel.split(path.sep).join '/'
      debug 'rel', rel, localDir, '->', otherDir
      paths.push rel
    value.paths = paths
    value.locals = ctx.locals.filter (el)-> el isnt name
  next()

saveAll = (ctx, next)->
  jsonPath = auto.option.componentJson
  fs.writeFile jsonPath, JSON.stringify(ctx.RootJson, null, 2), (err)->
    return next err if err 
    for own key, value of ctx.json
      fs.writeFile key, JSON.stringify(value, null, 2), (err)-> 

print = (ctx,next)->
  debug 'ctx = ', ctx
  next()
auto = (done)->
  debug 'auto start'
  # json = require './' + file

  # loadJson (err)->
  #   retriveLocals (err)->
  #     updateLocals (err)->
  #       spreadDependancy (err)->
  #         done()

  f = ho [
    loadRootJson
    retriveLocalsJon
    loadLocalJson
    # print 
    updateLocals
    # print 
    spreadDependancy
    saveAll
  ]

  f {}, (err, ctx)-> 
    debug 'err', err
    debug 'ctx', ctx


auto.option =  
  ignorePrefix: '!'
  componentJson : 'component.json'

module.exports = auto
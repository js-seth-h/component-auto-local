fs = require 'fs'
path = require 'path' 
debug = require('debug')('component-auto-local')
glob = require 'glob'
ho = require 'handover'
  
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

loadRootJson = (ctx, next)->
  loadJson auto.option.componentJson, (err, json)->
    ctx.RootJson = json
    next()
retriveLocalsJon = (ctx, next)-> 
  getLocalComponents = (dir, callback)->
    # directPath = path.join dir, "Component.json"
    # fs.exists directPath, (exist)->
    #   if exist
    #     callback null, [directPath]
    #   else
    jsonPattern = path.join dir, "*/Component.json"
    glob jsonPattern, callback
  debug 'paths = ', ctx.RootJson.paths  
  (ho.map getLocalComponents) ctx.RootJson.paths, (err, result)-> 
    # debug 'localjson ' , err, result
    return next err if err
    localDirs = result.reduce (a, b) ->  a.concat(b)
    ctx.localJsonPath = localDirs.filter (item)-> 
      name = path.basename path.dirname item
      return name[0] isnt auto.option.ignorePrefix 
    debug 'found localJsonPath =', ctx.localJsonPath 
    if ctx.localJsonPath.length is 0
      return next new Error "no local modules"
    next()

loadLocalJson = (ctx, next)-> 
  (ho.map loadJson) ctx.localJsonPath, (err, results)->
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
  done() 

spreadDependancy = (ctx, next)->
  debug 'spreadDependancy'

  for own key, value of ctx.json
    value.dependencies = ctx.RootJson.dependencies
    name = value.name
    paths = []
    localDir = path.dirname key
    for otherDir  in ctx.RootJson.paths
      # otherDir = path.dirname key2
      continue if localDir is otherDir
      rel = path.relative localDir, otherDir
      rel = rel.split(path.sep).join '/'
      debug 'rel', rel, localDir, '->', otherDir
      paths.push rel
    value.paths = paths
    value.locals = ctx.locals.filter (el)-> el isnt name
    debug 'localjson ', key, name, value
  next()

saveAll = (ctx, next)->
  jsonPath = auto.option.componentJson
  fs.writeFile jsonPath, JSON.stringify(ctx.RootJson, null, 2), (err)->
    return next err if err 

    saveJson = (filepath, jsonDef, done)->


      return done() if -1 <  filepath.indexOf 'node_modules/'
      return done() if -1 < filepath.indexOf 'components/' 

      debug 'saveJson', filepath, jsonDef
      fs.writeFile filepath, JSON.stringify(jsonDef, null, 2), done

    (ho.map saveJson) ctx.json, (err, results)->
      debug 'saveLocalJSON', err, results
      return next err if err
      next() 

print = (ctx,next)->
  debug 'ctx = ', ctx
  next()

auto = (done)->
  debug 'auto start'  
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
    debug "DONE!!!"
    done()

auto.option =  
  ignorePrefix: '!'
  componentJson : 'component.json'

module.exports = auto
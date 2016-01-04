fs = require 'fs'
path = require 'path' 
debug = require('debug')('component-auto-local')
glob = require 'glob'

ficent = require 'ficent'

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
    ctx.RootDir = path.dirname auto.option.componentJson
    ctx.RootJson = json
    next()

retriveLocalsJon = (ctx, next)-> 

  _getLocalComponents = (dir, callback)->
    jsonPattern = path.join dir, "*/component.json"
    debug 'search local component.json with', jsonPattern
    glob jsonPattern, callback
  debug 'ctx.RootDir =', ctx.RootDir  
  debug 'ctx.RootJson.paths =', ctx.RootJson.paths  

  # fns = []
  # for p in ctx.RootJson.paths
  #   do (p)->
  #     p = path.join ctx.RootDir, p 
  #     fns.push (toss)-> _getLocalComponents p, toss


  _fn = ficent.par (p, _toss)->
    p = path.join ctx.RootDir, p  
    _getLocalComponents p, _toss



  _fn ctx.RootJson.paths, (err, fpaths)->
    debug 'fork back', arguments


    dirs = fpaths.reduce ((a,b)-> a.concat b), []
    debug 'dirs ', dirs
    ctx.localJsonPath = dirs.filter (item)-> 
      name = path.basename path.dirname item
      return name[0] isnt auto.option.ignorePrefix 
    debug 'ctx.localJsonPath', ctx.localJsonPath
    # if ctx.localJsonPath.length is 0
    #   return next new Error "no local modules"
    next()


  return

loadLocalJson = (ctx, next)-> 
  
  # fns = []
  # for p in ctx.localJsonPath
  #   do (p)->
  #     fns.push (toss)-> loadJson p, toss
  _fn = ficent.par (p, _toss)->
    loadJson p, _toss

  _fn ctx.localJsonPath, (err, results)->
    debug 'loadLocalJson', err, results
    ctx.json = {}
    ctx.locals = []
    results.map (item, inx)->
      pathname = ctx.localJsonPath[inx]
      correctName = path.basename path.dirname pathname
      debug 'LocalJson path & name = ', pathname, item.name , correctName
      item.name = correctName
      ctx.json[pathname] = item
      ctx.locals.push item.name
    debug 'loadedJson', ctx
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
    for otherDir in ctx.RootJson.paths

      otherDir = path.join ctx.RootDir, otherDir
      # otherDir = path.dirname key2

      # ctx.RootDir = path.dirname auto.option.componentJson
      debug 'spreadDependancy', localDir, otherDir
      continue if path.normalize(localDir) is path.normalize(otherDir)

      rel = path.relative localDir, otherDir
      rel = rel.split(path.sep).join '/'
      # debug 'rel', rel, localDir, '->', otherDir
      paths.push rel
    value.paths = paths
    value.locals = ctx.locals.filter (el)-> el isnt name
    debug 'localjson ', key, name
    debug 're-defined JSON = ', JSON.stringify value, null, 2
  next()

saveAll = (ctx, next)->
  jsonPath = auto.option.componentJson
  fs.writeFile jsonPath, JSON.stringify(ctx.RootJson, null, 2), (err)->
    return next err if err 

    saveJson = (filepath, jsonDef, done)->
      # return done() if -1 <  filepath.indexOf 'node_modules/'
      # return done() if -1 < filepath.indexOf 'components/' 

      debug 'saveJson', filepath, jsonDef
      fs.writeFile filepath, JSON.stringify(jsonDef, null, 2), done


    debug 'ctx.json = ', JSON.stringify ctx.json, null, 2
    # fns = []
    # for own fpath, json of ctx.json
    #   do (fpath, json)->
    #     fns.push (toss)-> saveJson fpath, json, toss



    par_args = []
    for own fpath, json of ctx.json
      par_args.push [fpath, json]


    _fn = ficent.par (fpath, json, toss)-> 
      saveJson fpath, json, toss

    _fn par_args, (err, results)->
    # (ho.map saveJson) ctx.json, (err, results)->
      debug 'saveLocalJSON', err, results
      return next err if err
      next() 

print = (ctx,next)->
  debug 'ctx = ', ctx
  next()

auto = (done)->
  debug 'auto start'  
  f = ficent [
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
    done err

auto.option =  
  ignorePrefix: '!'
  componentJson : 'component.json'

module.exports = auto
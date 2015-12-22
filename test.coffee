process.env.DEBUG = "component-auto-local"

locals = require './component-auto-local'

locals.option.componentJson = 'test-component.json'  # it's default value
locals.option.componentJson = './test2/core/test-component.json'  # it's default value
locals.option.ignorePrefix = '!'                  # it's default value
locals  (err)->
  if err
    # console.error err 
    console.error err.stack
  console.log 'END'



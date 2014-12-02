process.env.DEBUG = "*"

locals = require './component-auto-local'

locals.option.componentJson = 'test-component.json'  # it's default value
locals.option.ignorePrefix = '!'                  # it's default value
locals  (err)->
  console.log 'END', err
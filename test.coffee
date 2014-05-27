

locals = require './component-auto-local'

locals.option.componentJson = 'component.json'  # it's default value
locals.option.ignorePrefix = '!'                  # it's default value
locals  (err)->
  console.log 'END', err
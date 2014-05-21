

locals = require './component-auto-local'

locals './component.json', (err)->
  console.log 'END', err
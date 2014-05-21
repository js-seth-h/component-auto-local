#component-auto-local

> Updating `locals` of `component.json` in `paths`


## Purpose

When I use [component][comp], I need a way to expose my own local module easy.
`locals` and `path` of `component.json` have advantage - look clear, but annoying.

So I made automatic updater for `locals` in `paths`.

[comp]: https://github.com/component


## How to work

1. read all subdir of `paths`
2. if `locals` in `component.json` is not exist, remove it.
4. if subdir name isn`t start with option.ignorePrefix (default `!`), Add subdir to `locals`.
4. overwrite `component.json`


## How to use

I use this in `buider.coffee/js`,  but it is not forced.

```coffee
fs = require("fs")
resolve = require("component-resolver")
build = require("component-builder")
coffee = require("builder-coffee-script")
less = require("component-builder-less")


locals = require './component-auto-local'

locals (err)->
  # resolve the dependency tree
  resolve process.cwd(),
    
    # install the remote components locally
    install: true
  , (err, tree) ->
    throw err  if err
    
    # only include `.js` files from components' `.scripts` field
    console.log tree
    
    build.scripts(tree)
      .use("scripts", build.plugins.js())
      .use("scripts", coffee())
      .end (err, string) ->
        throw err  if err
        fs.writeFileSync "public/build/build.js", build.scripts.require +  string
        return

    
    # only include `.css` files from components' `.styles` field
    build.styles(tree).use("styles", build.plugins.css()).use("styles", less({})).end (err, string) ->
      throw err  if err
      fs.writeFileSync "public/build/build.css", string
      return

```  

## License

(The MIT License)

Copyright (c) 2014 junsik &lt;js@seth.h@google.com&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


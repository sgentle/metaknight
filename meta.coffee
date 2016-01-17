parse = require('esprima').parse
generate = require('escodegen').generate
Immutable = require 'immutable'

setPrototypeOf = Object.setPrototypeOf or (obj, proto) -> obj.__proto__ = proto

isFunc = (tree) -> tree?.get('type') in ['FunctionExpression', 'ArrowFunctionExpression']

# This will not work if you try to assign to the variable being replaced
walkReplace = (tree, replacements) ->
  return tree unless tree?.get('type') or Immutable.List.isList(tree)
  if tree.get('type') is 'Identifier' and tree.get('name') of replacements
    replacements[tree.get('name')]
  else if isFunc(tree) and tree.get('params').some((x) -> replacements[x.get('name')]?)
    tree # Don't try to rename subfunctions
  else
    ret = tree
    shadowed = false
    tree.forEach (v, k) ->
      return unless !shadowed and v? and typeof v is 'object'
      if v?.get?('type') is 'VariableDeclaration' and v.get('declarations').some((x) -> replacements[x.getIn(['id', 'name'])]?)
        shadowed = true
      else
        ret = ret.set k, walkReplace(v, replacements)
    ret

walkAssign = (tree, replacements) ->
  for k, v of replacements
    replacements[k] = Immutable.Map { type: 'Literal', value: v }
  walkReplace tree, replacements

walkRename = (tree, replacements) ->
  for k, v of replacements
    replacements[k] = Immutable.Map { type: 'Identifier', name: v }
  walkReplace tree, replacements

stripReturns = (tree) ->
  return tree unless tree?.get('type') or Immutable.List.isList(tree)
  if tree.get('type') is 'ReturnStatement'
    Immutable.Map type: 'ExpressionStatement', 'expression': tree.get('argument')
  else if isFunc(tree)
    tree
  else
    ret = tree
    tree.forEach (v, k) ->
      ret = ret.set k, stripReturns v if v? and typeof v is 'object'
    ret

metaProto =
  curry: (args...) ->
    replacements = {}
    replacements[@ast.getIn ['params', i, 'name']] = arg for arg, i in args

    @assign replacements

  assign: (replacements) ->
    ast = @ast
      .set 'body', walkAssign @ast.get('body'), replacements
      .set 'params', @ast.get('params').filter (x) -> !replacements[x.get('name')]

    metaknight ast

  rename: (replacements) ->
    ast = walkRename @ast.set('type', 'ignoreme'), replacements
      .set('type', 'FunctionExpression')
    metaknight ast

  stripReturns: ->
    ast = @ast.set 'body', stripReturns @ast.get('body')
    metaknight ast

  concat: (other) ->
    bodyPath = ['body', 'body']

    ast = @ast
      .setIn bodyPath, @ast.getIn(bodyPath).concat other.ast.getIn(bodyPath)
      .set 'params', @ast.get('params').concat other.ast.get('params')
    metaknight ast

  reorder: (order) ->
    params = Immutable.List(order).map (n) => @ast.getIn ['params', n]
    metaknight @ast.set 'params', params


metaknight = (ast) ->
  if typeof ast is 'function'
    ast = Immutable.fromJS parse('('+ast.toString()+')').body[0].expression
  if ast?.get('type') isnt 'FunctionExpression'
    throw new Error "not a function"

  f = (args...) ->
    return f.curry(args...)() if args.length > 0

    jsast = ast.toJS()
    code = generate(jsast.body).slice(1, -1).trim() # get rid of braces
    paramNames = (param.name for param in jsast.params)
    new Function paramNames, code

  f.ast = ast
  setPrototypeOf f, metaProto
  f

module.exports = metaknight

module.exports = () ->
  Array.prototype.remove = (o) ->
    @splice @indexOf(o), 1

  class Util
    send: (res, data) ->
      res.json
        code: 0
        response: data

    sendError: (res, errorMessage) ->
      res.json
        code: 1
        response: errorMessage

    require: (res, args, required) =>
      for arg in required
        if !(args[arg]?)
          @sendError res, "Not enough arguments"
          return false
      return true

    optional: (args, opts) =>
      for arg of opts
        if !(args[arg]?)
          args[arg] = opts[arg]
        # wrap related in array
        if arg == 'related' and args[arg] not instanceof Array
          args[arg] = [args[arg]]


  return new Util()
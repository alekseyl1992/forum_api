module.exports = () ->
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


  return new Util()
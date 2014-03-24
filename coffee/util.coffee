module.exports = () ->
  class Util
    datasetToJSON: (data) ->
      JSON.stringify
        code: 0
        response: data

    sendError: (res, errorMessage) ->
      res.send JSON.stringify
        code: 1
        response: errorMessage

    require: (res, args, required) =>
      for arg in required
        if !args[arg]?
          @sendError res, "Not enough arguments"
          return false
      return true

    optional: (args, opts) =>
      for arg in opts
        if !args[arg]?
          args[arg] = opts[arg]


  return new Util()
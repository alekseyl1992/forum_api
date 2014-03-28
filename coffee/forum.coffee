module.exports = (pool, async, util, user) ->
  class Forum
    create: (req, res) ->
      return if !util.require res, req.body, ["name", "short_name", "user"]

      pool.query "insert into forum
                  (name, short_name, user)
                  values(?, ?, ?)",
        [
          req.body.name,
          req.body.short_name,
          req.body.user
        ], (err, info) ->
          throw err if err and err != "ER_DUP_ENTRY"

          data = req.body
          data.id = info.insertId
          util.send res, data

    details: (req, res) ->
      return if !util.require res, req.query, ["forum"]
      util.optional req.query,
        related: []

      pool.query "select * from forum where short_name = ?",
        [req.query.short_name], (err, rows) =>
          throw err if err

          if 'user' in req.query.related
            user._details req, res, (err, data) =>
              rows.user = data
              util.send res, rows
          else
            util.send res, rows

    listPosts: (req, res) ->
      return if !util.require res, req.query, ["forum"]
      util.optional req.query,
        related: []

      # to join or not to join, that is the question

    listThreads: (req, res) ->

    listUsers: (req, res) ->

  return new Forum()
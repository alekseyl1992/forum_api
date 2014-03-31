module.exports = (pool, async, util, modules) ->
  class Forum
    _getId: (short_name, cb) ->
      pool.query "select id from forum where short_name = ?",
        [short_name], (err, rows) ->
        if err || rows.length == 0
          errMessage = "Unable to get forumId"
          util.sendError(res, errMessage)
          cb errMessage, null
        else
          cb null, rows[0].id

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

    _details: (req, res, cb) ->
      return if !util.require res, req.query, ["forum"]
      util.optional req.query,
        related: []

      pool.query "select * from forum where short_name = ?",
        [req.query.forum], (err, rows) =>
          util.sendError res, err if err

          postData = rows[0]
          if 'user' in req.query.related
            req.query.user = postData.user
            modules.user._details req, res, postData.user, (err, data) =>
              postData.user = data
              cb null, postData
          else
            cb null, postData

    details: (req, res) =>
      @_details req, res, (err, rows) =>
        util.send res, rows

    listPosts: (req, res) ->
      modules.post.list req, res

    listThreads: (req, res) ->
      modules.thread.list req, res

    listUsers: (req, res) ->
      return if !util.require res, req.query, ["forum"]
      util.optional req.query,
        related: []

      query = "select distinct user.* from post
              join user on post.user = user.email
              where post.forum = ?"
      if req.query.since_id?
        query += " offset " + req.query.since_id

      query += " order by post.date"
      if req.query.order?
        query += " " + req.query.order

      if req.query.limit?
        query += " limit " + req.query.limit

      pool.query query, [req.query.forum], (err, rows) =>
        if err
          util.sendError res, "Unable to list forum users"
          console.log(err)
          return

        util.send res, rows

  return new Forum()
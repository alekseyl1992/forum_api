module.exports = (pool, async, util, modules) ->
  class Post
    create: (req, res) ->
      return if !util.require res, req.body, ["date", "thread", "message", "user", "forum"]
      util.optional req.body,
        parent: null,
        isApproved: false,
        isHighlighted: false,
        isEdited: false,
        isSpam: false,
        isDeleted: false

      pool.query "insert into post
                  (date, thread, forum, message, user,
                    parent, isApproved, isHighlighted, isEdited, isSpam, isDeleted, likes, dislikes)
                  values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
          req.body.date,
          req.body.thread,
          req.body.forum,
          req.body.message,
          req.body.user,
          req.body.parent,
          req.body.isApproved,
          req.body.isHighlighted,
          req.body.isEdited,
          req.body.isSpam,
          req.body.isDeleted,
          0, # likes
          0  # dislikes
        ], (err, info) ->
          if err and err != "ER_DUP_ENTRY"
            util.sendError res, "Unable to create post"
            console.log(err)
            return

          data = req.body
          data.id = info.insertId
          util.send res, data


    _details: (req, res, cb) ->
      return if !util.require res, req.query, ["post"]
      util.optional req.query,
        related: []

      pool.query "select * from post where id = ?",
        [req.query.post], (err, rows) =>
          if err
            util.sendError(res, "Unable to get details")
            console.log(err)
            return

          if rows.length == 0
            util.sendError(res, "No such post")
            return

          postData = rows[0]
          postData.points = postData.likes - postData.dislikes

          if !(req.query.related?)
            cb null, postData
            return

          relatedTasks = {}
          if "thread" in req.query.related
            req.query.related.remove("thread") # prevent futher relating
            req.query.thread = postData.thread
            relatedTasks.thread = (cb) =>
              modules.thread._details req, res, cb
          if "forum" in req.query.related
            req.query.related.remove("forum")
            req.query.forum = postData.forum
            relatedTasks.forum = (cb) =>
              modules.forum._details req, res, cb
          if "user" in req.query.related
            req.query.related.remove("user")
            req.query.user = postData.user
            relatedTasks.user = (cb) =>
              modules.user._details req, res, postData.user, cb

          async.parallel relatedTasks, (err, data) =>
            if err
              util.sendError(res, "Unable to get details")
              console.log(err)
              return

            postData.thread = data.thread if data.thread?
            postData.forum = data.forum if data.forum?
            postData.user = data.user if data.user?

            cb null, postData


    details: (req, res) =>
      @_details req, res, (err, data) =>
        util.send res, data

    list: (req, res) ->
      if req.query.forum?
        selector = "forum"
        value = req.query.forum
      else if req.query.thread?
        selector = "thread"
        value = req.query.thread
      else
        util.sendError res, "Forum and thread not specified"
        return

      query = "select * from post where " + selector + " = ?"
      if req.query.since?
        query += " and date >= " + pool.escape(req.query.since)

      query += " order by date"
      if req.query.order == "asc"
        query += " asc"
      else if req.query.order == "desc"
        query += " desc"

      if req.query.limit?
        query += " limit " + parseInt(req.query.limit)

      pool.query query, [value], (err, rows) =>
        if err
          util.sendError res, "Unable to list posts"
          console.log(err)
          return

        row.points = row.likes - row.dislikes for row in rows
        util.send res, rows


    remove: (req, res) ->
      return if !util.require res, req.body, ["post"]

      pool.query "update post set isDeleted = 1
                  where id = ?",
        [req.body.post],
        (err, info) =>
          if err
            util.sendError(res, "Unable to remove post")
            console.log(err)
            return

          util.send res, req.body


    restore: (req, res) ->
      return if !util.require res, req.body, ["post"]

      pool.query "update post set isDeleted = 0
                        where id = ?",
        [req.body.post],
        (err, info) =>
          if err
            util.sendError(res, "Unable to restore post")
            console.log(err)
            return

          util.send res, req.body

    update: (req, res) =>
      return if !util.require res, req.body, ["post", "message"]

      pool.query "update post set isEdited = 1, message = ?
                  where id = ?",
        [req.body.message, req.body.post],
        (err, info) =>
          if err
            util.sendError(res, "Unable to update post")
            console.log(err)
            return

          req.query = {post: req.body.post}
          @_details req, res, (err, data) =>
            util.send res, data

    vote: (req, res) =>
      return if !util.require res, req.body, ["post", "vote"]

      if req.body.vote == 1
        query = "update post set likes = likes + 1"
      else if req.body.vote == -1
        query = "update post set dislikes = dislikes + 1"
      else
        util.sendError(res, "vote value should be either -1 or 1")
        return

      pool.query query + " where id = ?",
        [req.body.post],
        (err, info) =>
          if err
            util.sendError(res, "Unable to vote for post")
            console.log(err)
            return

          req.query = {post: req.body.post}
          @_details req, res, (err, data) =>
            util.send res, data

  return new Post()
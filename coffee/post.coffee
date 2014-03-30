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
                  (date, thread_id, forum, message, user,
                    parent_id, isApproved, isHighlighted, isEdited, isSpam, isDeleted)
                  values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
          req.body.date,
          req.body.forum,
          req.body.thread,
          req.body.message,
          req.body.user,
          req.body.parent,
          req.body.isApproved,
          req.body.isHighlighted,
          req.body.isEdited,
          req.body.isSpam,
          req.body.isDeleted
        ], (err, info) ->
          throw err if err and err != "ER_DUP_ENTRY"

          data = req.body
          data.id = info.insertId
          util.send res, data


    _details: (req, res, cb) ->
      return if !util.require res, req.query, ["post"]
      util.optional req.body,
        related: []

      pool.query "select * from post where id = ?",
        [req.query.post], (err, rows) =>
          if err
            cb err, null
            return

          if rows.length == 0
            util.sendError(res, "No such post")
            return

          postData = rows[0]

          if req.query.related.length == 0
            cb null, postData
            return

          relatedTasks = {}
          if "thread" in req.query.related
            relatedTasks.thread = (cb) =>
              modules.thread._details req, res, cb
          if "forum" in req.query.related
            relatedTasks.forum = (cb) =>
              modules.forum._details req, res, cb
          if "user" in req.query.related
            relatedTasks.user = (cb) =>
              modules.user._details req, res, cb

          async.parallel relatedTasks, (err, data) =>
            if err
              cb err, null
              return

            postData.thread = data.thread if data.thread?
            postData.forum = data.forum if data.forum?
            postData.user = data.user if data.user?

            cb null, postData


    details: (req, res) =>
      @_details req, res, (err, data) =>
        util.send data

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
        query += " and date >= " + req.query.since

      query += " order by date"
      if req.query.order?
        query += " " + req.query.order

      if req.query.limit?
        query += " limit " + req.query.limit

      pool.query query, [value], (err, rows) =>
        if err
          util.sendError res, "Unable to list posts"
          return

        util.send res, rows


    remove: (req, res) ->
      return if !util.require res, req.body, ["post"]

      pool.query "update post set isRemoved = 1
                  where id = ?",
        [req.body.post],
        (err, info) =>
          if err
            util.sendError(res, "Unable to remove post")

          util.send res, data


    restore: (req, res) ->
      return if !util.require res, req.body, ["post"]

      pool.query "update post set isRemoved = 0
                        where id = ?",
        [req.body.post],
          (err, info) =>
          if err
            util.sendError(res, "Unable to restore post")

          util.send res, {post: req.body.post}

    update: (req, res) =>
      return if !util.require res, req.body, ["post", "message"]

      pool.query "update post set isEdited = 1, message = ?
                  where id = ?",
        [req.body.message, req.body.post],
        (err, info) =>
          if err
            util.sendError(res, "Unable to update post")

          @_details(res, req, req.body.post)

    vote: (req, res) =>
      return if !util.require res, req.body, ["post", "vote"]

      if req.body.vote == "1"
        query = "update post set likes = likes + 1"
      else if req.body.vote == "-1"
        query = "update post set dislikes = dislikes + 1"
      else
        util.sendError(res, "vote value should be either -1 or 1")
        return

        pool.query query + " where id = ?",
          [req.body.post],
        (err, info) =>
          if err
            util.sendError(res, "Unable to vote for post")
            return

          @_details res, req, (err, data) =>
            util.send res, data

  return new Post()
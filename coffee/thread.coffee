module.exports = (pool, async, util, modules) ->
  class Thread
    create: (req, res) ->
      return if !util.require res, req.body, ["forum", "title", "isClosed", "user", "date", "message", "slug"]
      util.optional req.body,
        isDeleted: false

        #async.parallel
        #  userId: (cb) -> modules.user._getId res, req.body.user, cb
        #  forumId: (cb) -> modules.forum._getId res, req.body.forum, cb
        #, actualCreate

        pool.query "insert into thread
                    (title, slug, date, isClosed, isDeleted,
                      message, likes, dislikes, forum, user)
                    values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          [
            req.body.title,
            req.body.slug,
            req.body.date,
            req.body.isClosed,
            req.body.isDeleted,
            req.body.message,
            0, #likes
            0, #dislikes
            req.body.forum,
            req.body.user
          ], (err, info) ->
            throw err if err and err != "ER_DUP_ENTRY"
            if err == "ER_DUP_ENTRY"
              util.sendError(res, "Duplicate entry (thread.slug)")

            data = req.body
            data.id = info.insertId
            util.send res, data

    _details: (req, res, cb) ->
      return if !util.require res, req.query, ["thread"]
      util.optional req.query,
        related: []

      pool.query "select * from thread where id = ?",
        [req.query.thread], (err, rows) =>
          if err
            util.sendError(res, err)
            return

          if rows.length == 0
            util.sendError(res, "No such thread")
            return

          postData = rows[0]

          if req.query.related.length == 0
            cb null, postData
            return

          relatedTasks = {}
          
          if "user" in req.query.related
            req.query.related.remove("user") #prevent for futher detailing
            req.query.user = postData.user
            relatedTasks.user = (cb) =>
              modules.user._details req, res, postData.user, cb #todo: whyyyy
          if "forum" in req.query.related
            req.query.related.remove("user")
            req.query.forum = postData.forum
            relatedTasks.forum = (cb) =>
              modules.forum._details req, res, cb

          async.parallel relatedTasks, (err, data) =>
            if err
              util.sendError(res, err)
              return

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
      else if req.query.user?
        selector = "user"
        value = req.query.user
      else
        util.sendError res, "Forum and user not specified"
        return

      query = "select * from thread where " + selector + " = ?"
      if req.query.since?
        query += " and date >= " + pool.escape(req.query.since)

      query += " order by date"
      if req.query.order?
        query += " " + pool.escape(req.query.order)

      if req.query.limit?
        query += " limit " + pool.escape(req.query.limit)

      pool.query query, [value], (err, rows) =>
        if err
          util.sendError res, "Unable to list threads"
          console.log(err)
          return

        util.send res, rows

    listPosts: (req, res) ->
      modules.post.list req, res

    _setFlag: (req, res, flag, to) =>
      return if !util.require res, req.body, ["thread"]

      pool.query "update thread set " + flag + " = " + to + " where id = ?",
        [req.body.thread],
      (err, info) =>
        if err
          util.sendError(res, "Unable to set " + flag + " to " + to + "for thread")
          console.log(err)

        util.send res, {thread: req.body.thread}

    open: (req, res) =>
      @_setFlag(req, res, "isClosed", 0);

    close: (req, res) =>
      @_setFlag(req, res, "isClosed", 1);

    remove: (req, res) =>
      @_setFlag(req, res, "isDeleted", 1);

    restore: (req, res) =>
      @_setFlag(req, res, "isDeleted", 0);


    subscribe: (req, res) =>
      return if !util.require res, req.body, ["thread", "user"]

      pool.query "insert into subscribtion (user, thread_id) values (?, ?)",
        [req.body.user, req.body.thread], (err, info) =>
          if err
            util.sendError(res, "Unable to subscribe") # todo: composite unique?
            return

          util.send res, req.body


    unsubscribe: (req, res) =>
      return if !util.require res, req.body, ["thread", "user"]

      pool.query "delete from subscribtion where user_id = ? and thread_id = ?",
        [req.body.user, req.body.thread], (err, info) =>
          if err
            util.sendError(res, "Unable to unsubscribe")
            return

            util.send res, req.body

    update: (req, res) =>
      return if !util.require res, req.body, ["message", "slug", "thread"]

      pool.query "update thread set message = ?, slug = ?, where id = ?",
        [res.body.message, res.body.slug, res.body.thread],
        (err, info) =>
          if err
            util.sendError(res, "Unable to update thread")
            return
          @_details res, req, (err, data) =>
            util.send res, data

    vote: (req, res) =>
      return if !util.require res, req.body, ["vote", "thread"]

      if req.body.vote == "1"
        query = "update thread set likes = likes + 1"
      else if req.body.vote == "-1"
        query = "update thread set dislikes = dislikes + 1"
      else
        util.sendError(res, "vote value should be either -1 or 1")
        return

        pool.query query + " where id = ?",
          [req.body.thread],
          (err, info) =>
            if err
              util.sendError(res, "Unable to vote for thread")
              return

            @_details res, req, (err, data) =>
              util.send res, data

  return new Thread()
module.exports = (pool, async, util, user, forum) ->
  class Thread
    create: (req, res) ->
      return if !util.require res, req.body, ["forum", "title", "isClosed", "user", "date", "message", "slug"]
      util.optional req.body,
        isDeleted: false

        async.parallel
          userId: (cb) -> user._getId res, req.body.user, cb
          forumId: (cb) -> forum._getId res, req.body.forum, cb
        , actualCreate


      actualCreate = (err, data) =>
        pool.query "insert into thread
                    (title, slug, date, isClosed, isDeleted,
                      message, user, likes, dislikes, forum_id, user_id)
                    values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
          req.body.title,
          req.body.slug,
          req.body.date,
          req.body.isClosed,
          req.body.isDeleted,
          req.body.message,
          req.body.user,
          0, #likes
          0, #dislikes
          data.forumId,
          data.userId
        ], (err, info) ->
        throw err if err and err != "ER_DUP_ENTRY"
        if err == "ER_DUP_ENTRY"
          util.sendError(res, "Duplicate entry (thread.slug)") # TODO: make slug unique

        data = req.body
        data.id = info.insertId
        util.send res, data

    _details: (req, res, cb) ->


    details: (req, res) =>
      @_details req, res, (err, data) =>
        util.send res, data

    list: (req, res) ->

    listPosts: (req, res) ->

    _setFlag: (req, res, flag, to) =>
      return if !util.require res, req.body, ["thread"]

      pool.query "update thread set " + flag + " = " + to + " where id = ?",
        [req.body.thread],
      (err, info) =>
        if err
          util.sendError(res, "Unable to set " + flag + " to " + to + "for thread")

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

      user._getId req.body.user, (err, userId) =>
        return if err
        pool.query "insert into subscribtion (user_id, thread_id) values (?, ?)",
          [userId, req.body.thread], (err, info) =>
            if err
              util.sendError(res, "Unable to subscribe") # todo: composite unique?
              return

            util.send res, req.body


    unsubscribe: (req, res) =>
      return if !util.require res, req.body, ["thread", "user"]

        user._getId req.body.user, (err, userId) =>
          return if err

          pool.query "delete from subscribtion where user_id = ? and thread_id = ?",
            [userId, req.body.thread], (err, info) =>
              if err
                util.sendError(res, "Unable to unsubscribe") # todo: composite unique?
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
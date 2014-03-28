module.exports = (pool, async, util) ->
  class Post

    # todo: not done yet
    create: (req, res) ->
      return if !util.require res, req.body, ["date", "thread", "message", "user", "forum"]
      util.optional req.body,
        parent: null,
        isApproved: false,
        isHighlighted: false,
        isEdited: false,
        isSpam: false,
        isDeleted: false

      # get thread and forum id
      threadId = 0
      forumId = 0

      pool.query "insert into post
                  (date, thread_id, forum_id, message, user,
                    parent_id, isApproved, isHighlighted, isEdited, isSpam, isDeleted)
                  values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
          req.body.date,
          forumId,
          threadId,
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


    _details: (req, res) ->

    details: (req, res) ->

    list: (req, res) ->

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

    vote: (req, res) ->

  return new Post()
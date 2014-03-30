module.exports = (pool, async, util) ->
  class User
    create: (req, res) ->
      return if !util.require res, req.body, ["username", "about", "name", "email"]
      util.optional req.body,
        isAnonymous: false

      pool.query "insert into user
                  (username, about, name, email, isAnonymous)
                  values(?, ?, ?, ?, ?)",
      [
        req.body.username
        req.body.about
        req.body.name
        req.body.email
        req.body.isAnonymous
      ], (err, info) ->
        throw err if err and err != "ER_DUP_ENTRY"

        util.send res, req.body

    _getId: (res, email, cb) =>
      pool.query "select id from user where email = ?",
        [req.body.user], (err, rows) =>
        if err || rows.length == 0
          errMessage = "Unable to get userId"
          util.sendError(res, errMessage)
          cb errMessage, null
        else
          cb null, rows[0].id

    _details: (req, res, user, cb) =>
      cb = cb || ->

      pool.query "select * from user where email = ?",
        [user], (err, rows) ->
          throw err if err
          if rows.length is 0
            util.sendError(res, "User not found")
            return

          userId = rows[0].id
          email = rows[0].email
          subscriptions = []
          followers = []
          following = []
          async.parallel [
            (callback) ->
              pool.query "select thread_id from subscription where user = ?",
                [user], (err, rows) ->
                  throw err if err
                  subscriptions = (row.thread_id for row in rows)
                  callback null, null

            (callback) ->
              pool.query "select follower from follow where followee = ?",
                [email], (err, rows) ->
                  throw err if err
                  followers = (row.follower for row in rows)
                  callback null, null

            (callback) ->
              pool.query "select followee from follow where follower = ?",
                [email], (err, rows) ->
                  throw err if err
                  following = (row.followee for row in rows)
                  callback null, null
          ], ->
            data = rows[0]
            data.subscriptions = subscriptions || []
            data.followers = followers || []
            data.following = following || []

            cb null, data

    details: (req, res) =>
      @_details req, res, req.query.user,
        (err, data) => util.send res, data


    follow: (req, res) =>
      return if !util.require res, req.body, ["follower", "followee"]

      pool.query "select count(*) from follow where follower = ? and followee = ?",
        [req.body.follower, req.body.followee], (err, rows) =>
          if rows.length is not 0
            @details req, res
            return

          pool.query "insert into follow (follower, followee) values(?, ?)",
            [req.body.follower, req.body.followee], (err, rows) =>
              throw err if err
              req.query = {user: req.body.follower}
              @details req, res


    listFollowers: (req, res) =>
      return if !util.require res, req.query, ["user"]

      query = "select follower from follow
              join user on user.email = follow.follower
              where followee = ?
              order by name"
      if req.query.order?
        query += " " + req.query.order
      if req.query.since_id?
        query += " " + "offset " + req.query.since_id
      if req.query.limit?
        query += " " + "limit " + req.query.limit

      pool.query query,
        [req.query.user], (err, rows) =>
          throw err if err
          followers = (row.follower for row in rows)
          async.mapSeries followers, ((follower, cb) => @_details(req, res, follower, cb)),
            (err, results) ->
              util.send res, results


    listFollowing: (req, res) =>
      return if !util.require res, req.query, ["user"]

      query = "select followee from follow
                join user on user.email = follow.follower
                where follower = ?
                order by name"
      if req.query.order?
        query += " " + req.query.order
      if req.query.since_id?
        query += " " + "offset " + req.query.since_id
      if req.query.limit?
        query += " " + "limit " + req.query.limit

      pool.query query,
        [req.query.user], (err, rows) =>
          throw err if err
          followees = (row.followee for row in rows)
          async.mapSeries followees, ((followee, cb) => @_details(req, res, followee, cb)),
            (err, results) ->
              util.send res, results


    listPosts: (req, res) ->
      return if !util.require res, req.query, ["user"]

      query = "select * from post
                join user on user.email = post.user
                where user.email = ?"

      if req.query.since?
        query += " " + " and date >= " + req.query.since

      query += " order by date"
      if req.query.order?
        query += " " + req.query.order

      if req.query.limit?
        query += " " + "limit " + req.query.limit

      pool.query query,
        [req.query.user], (err, rows) =>
          if err
            util.sendError("Unable to list user posts", err)
            console.log(err)
            return

          row.user = req.query.user for row in rows
          util.send res, rows


    unfollow: (req, res) =>
      return if !util.require res, req.body, ["follower", "followee"]

      pool.query "delete from follow where follower = ? and followee = ? limit 1",
        [req.body.follower, req.body.followee], (err, rows) =>
          if err
            util.sendError("Unable to unfollow", err)
            console.log(err)
            return

          req.query = {user: req.body.follower}
          @details req, res

    updateProfile: (req, res) =>
      return if !util.require res, req.body, ["about", "user", "name"]

      pool.query "update user set name = ?, about = ? where email = ?",
        [req.body.name, req.body.about, req.body.user], (err, rows) =>
          if err
            util.sendError("Unable to update profile", err)
            console.log(err)
            return

          req.query = {user: req.body.user}
          @details req, res

  return new User
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
        throw err  if err
        pool.query "select * from user where email = ?",
          [req.body.email], (err, rows) ->
          throw err  if err
          res.send util.datasetToJSON(rows[0])


    _details: (req, res, user, cb) =>
      pool.query "select * from user where email = ?",
        [user], (err, rows) ->
          throw err if err
          if rows.length is 0
            res.status(404).send "User not found"
            return

          userId = rows[0].id
          email = rows[0].email
          subscriptions = []
          followers = []
          following = []
          async.parallel [
            (callback) ->
              pool.query "select thread_id from subscription where user_id = ?",
                [userId], (err, rows) ->
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
            data.subscriptions = subscriptions
            data.followers = followers
            data.following = following

            cb null, data

    details: (req, res) =>
      @_details(req, res, req.query.user,
        (err, data) => res.send util.datasetToJSON(data));


    follow: (req, res) =>
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
      query = "select follower from follow where followee = ?
              join user on user.email = follow.follower
              order by name"
      if req.query.order?
        query += " " + req.query.order
      if req.query.since_id?
        query += " " + "offset " + req.query.since_id
      if req.query.limit?
        query += " " + "limit" + req.query.limit

      pool.query query,
        [req.query.user], (err, rows) =>
          throw err if err
          followers = (row.follower for row in rows)
          async.mapSeries(followers, @_details, (err, results) ->
            res.send(util.datasetToJSON(results)))


    listFollowing: (req, res) =>
      query = "select followee from follow where followerfollower = ?
                join user on user.email = follow.follower
                order by name"
      if req.query.order?
        query += " " + req.query.order
      if req.query.since_id?
        query += " " + "offset " + req.query.since_id
      if req.query.limit?
        query += " " + "limit" + req.query.limit

      pool.query query,
        [req.query.user], (err, rows) =>
        throw err if err
        followees = (row.followee for row in rows)
        async.mapSeries(followees, @_details, (err, results) ->
          res.send(util.datasetToJSON(results)))


    listPosts: (req, res) ->
      query = "select * from post
                join user on user.id = post.user_id
                where user.email = ?"

      if req.query.since?
        query += " " + " and date >= " + req.query.since

      query += " order by date"
      if req.query.order?
        query += " " + req.query.order

      if req.query.limit?
        query += " " + "limit" + req.query.limit

      pool.query query,
        [req.query.user], (err, rows) =>
          row.user = req.query.user from row in rows
          res.send(util.datasetToJSON(rows))


    unfollow: (req, res) =>
      pool.query "delete from follow where follower = ? and followee = ? limit 1",
        [req.body.follower, req.body.followee], (err, rows) =>
          throw err if err
          req.query = {user: req.body.follower}
          @details req, res

    updateProfile: (req, res) ->
      pool.query "update user set name = ?, about = ? where email = ?",
        [req.body.name, req.body.about, req.body.user], (err, rows) =>
          throw err if err
          req.query = {user: req.body.user}
          @details req, res

  return new User
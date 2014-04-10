module.exports = (pool, async, util, modules) ->
  class DB
    clear: (req, res) ->
      queries =
        [
          "SET FOREIGN_KEY_CHECKS=0;"
          "TRUNCATE TABLE user;"
          "TRUNCATE TABLE forum;"
          "TRUNCATE TABLE thread;"
          "TRUNCATE TABLE post;"
          "TRUNCATE TABLE follow;"
          "TRUNCATE TABLE subscription;"
          "SET FOREIGN_KEY_CHECKS=1;"
        ]

      pool.getConnection (err, connection) ->
        if err
          util.sendError res, "Unable to clear db"
          console.log(err)
          return

        executor = (query, cb) ->
          connection.query query, (err, info) ->
            if err
              cb err
            else
              cb null

        async.eachSeries queries, executor, (err) ->
          connection.release();
          if err
            util.sendError res, "Unable to clear db"
            console.log(err)
          else
            util.send res, {"status": "db cleared successfully"}

  return new DB()

module.exports = function(pool, async) {
    var datasetToJSON = function(data) {
        return JSON.stringify({
            code: 0,
            response: data
        });
    };

    return {
        create: function(req, res) {
            console.log(req.body);
            pool.query('insert into user' +
                '(username, about, name, email, isAnonymous)' +
                'values(?, ?, ?, ?, ?)',
                [req.body.username,
                    req.body.about,
                    req.body.name,
                    req.body.email,
                    req.body.isAnonymous || false],
                function(err) {
                    if (err) throw err;
                    pool.query('select * from user where email = ?',
                        [req.body.email], function(err, rows) {
                            if (err) throw err;
                            res.send(datasetToJSON(rows[0]));
                        });
            });
        },

        details: function(req, res) {
            pool.query('select * from user where email = ?',
                [req.query.user], function(err, rows) {
                    if (err) throw err;

                    if (rows.length == 0) {
                        res.status(404).send("User not found");
                        return;
                    }

                    var userId = rows[0].id;
                    var email = rows[0].email;
                    var subscriptions = [];
                    var followers = [];
                    var following = [];

                    async.parallel([
                        function(callback) {
                            pool.query('select thread_id from subscription where user_id = ?',
                                [userId], function(err, rows) {
                                    if (err) throw err;
                                    for (var row in rows)
                                        subscriptions.push(row.thread_id);
                                    callback(null, null);
                                });
                        },
                        function(callback) {
                            pool.query('select follower from follow where followee = ?',
                                [email], function(err, rows) {
                                    if (err) throw err;
                                    for (var row in rows)
                                        followers.push(row.follower);
                                    callback(null, null);
                                });
                        },
                        function(callback) {
                            pool.query('select followee from follow where follower = ?',
                                [email], function(err, rows) {
                                    if (err) throw err;
                                    for (var row in rows)
                                        following.push(row.followee);
                                    callback(null, null);
                                });
                        }],
                        function() {
                            var data = rows[0];
                            data.subscriptions = subscriptions;
                            data.followers = followers;
                            data.following = following;
                            res.send(datasetToJSON(rows[0]));
                        });
                });
        },

        follow: function(req, res) {
        },

        listFollowers: function(req, res) {
        },

        listFollowing: function(req, res) {
        },

        listPosts: function(req, res) {
        },

        unfollow: function(req, res) {
        },

        updateProfile: function(req, res) {
        }
    }
};

module.exports = function(pool) {
    var datasetToJSON = function(data) {
        return JSON.stringify({
            code: 0,
            response: data
        });
    };

    return {
        create: function(req, res) {
            console.log(req.body);
            pool.query('insert into user (username, about, name, email, isAnonymous) values(?, ?, ?, ?, ?)',
                [req.body.username, req.body.about, req.body.name, req.body.email, req.body.isAnonymous || false],
                function(err, rows, fields) {
                    if (err) throw err;
                    pool.query('select * from user where email = ?',
                        [req.body.email], function(err, rows, fields) {
                            if (err) throw err;
                            res.send(datasetToJSON(rows[0]));
                        });
            });
        },

        details: function(req, res) {
            pool.query('select * from user ' +
                'where email = ?',
                [req.body.email], function(err, rows, fields) {
                    if (err) throw err;
                    res.send(datasetToJSON(rows[0]));
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
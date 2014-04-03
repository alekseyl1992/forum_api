express = require("express")
path = require("path") # модуль для парсинга пути
app = express()
async = require("async")
app.use express.logger("dev") # выводим все запросы со статусами в консоль
app.use express.bodyParser() # стандартный модуль, для парсинга JSON в запросах
app.use app.router # модуль для простого задания обработчиков путей

#mysql configuration
mysql = require("mysql")
pool = mysql.createPool(
  host: "127.0.0.1"
  database: "forum_api"
  user: "forum_api_user"
  password: "forum_api_pswd"
  dateStrings: true
)

#modules
modules = {}
util  = modules.util  = require("./util.coffee")()
user  = modules.user  = require("./user.coffee")(pool, async, util)
forum = modules.forum = require("./forum.coffee")(pool, async, util, modules)
thread= modules.thread= require("./thread.coffee")(pool, async, util, modules)
post  = modules.post  = require("./post.coffee")(pool, async, util, modules)

#routing
api_prefix = ""
app.get api_prefix + "/", (req, res) ->
  res.send "Welcome to forum_api!"

app.post api_prefix + "/forum/create", forum.create
app.get api_prefix + "/forum/details", forum.details
app.get api_prefix + "/forum/listPosts", forum.listPosts
app.get api_prefix + "/forum/listThreads", forum.listThreads
app.get api_prefix + "/forum/listUsers", forum.listUsers

app.post api_prefix + "/thread/close", thread.close
app.post api_prefix + "/thread/create", thread.create
app.get api_prefix + "/thread/details", thread.details
app.get api_prefix + "/thread/list", thread.list
app.get api_prefix + "/thread/listPosts", thread.listPosts
app.post api_prefix + "/thread/open", thread.open
app.post api_prefix + "/thread/subscribe", thread.subscribe
app.post api_prefix + "/thread/unsubscribe", thread.unsubscribe
app.post api_prefix + "/thread/update", thread.update
app.post api_prefix + "/thread/vote", thread.vote

app.post api_prefix + "/post/create", post.create
app.get api_prefix + "/post/details", post.details
app.get api_prefix + "/post/list", post.list
app.post api_prefix + "/post/remove", post.remove
app.post api_prefix + "/post/restore", post.restore
app.post api_prefix + "/post/update", post.update
app.post api_prefix + "/post/vote", post.vote

app.post api_prefix + "/user/create", user.create
app.get api_prefix + "/user/details", user.details
app.post api_prefix + "/user/follow", user.follow
app.get api_prefix + "/user/listFollowers", user.listFollowers
app.get api_prefix + "/user/listFollowing", user.listFollowing
app.get api_prefix + "/user/listPosts", user.listPosts
app.post api_prefix + "/user/unfollow", user.unfollow
app.post api_prefix + "/user/updateProfile", user.updateProfile

#http-server setup
http_port = 8084
app.listen http_port, ->
  console.log "Express server listening on port " + http_port

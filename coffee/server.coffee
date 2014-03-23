express = require("express")
path = require("path") # модуль для парсинга пути
app = express()
async = require("async")
app.use express.logger("dev") # выводим все запросы со статусами в консоль
app.use express.bodyParser() # стандартный модуль, для парсинга JSON в запросах
app.use express.methodOverride() # поддержка put и delete
app.use app.router # модуль для простого задания обработчиков путей
app.use express.static(path.join(__dirname, "public")) # запуск статического файлового сервера, который смотрит на папку public/ (в нашем случае отдает index.html)

#mysql configuration
mysql = require("mysql")
pool = mysql.createPool(
  host: "127.0.0.1"
  database: "forum_api"
  user: "forum_api_user"
  password: "forum_api_pswd"
)

#modules
forum = require("./forum.coffee")(pool, async)
thread = require("./thread.coffee")(pool, async)
post = require("./post.coffee")(pool, async)
user = require("./user.coffee")(pool, async)

#routing
api_prefix = ""
app.get api_prefix + "/", (req, res) ->
  pool.query "SELECT 1 + 1 AS solution", (err, rows, fields) ->
    throw err  if err
    res.send "The solution is: " + rows[0].solution
    return

  return

app.get api_prefix + "/forum/create", forum.create
app.get api_prefix + "/forum/details", forum.details
app.get api_prefix + "/forum/listPosts", forum.listPosts
app.get api_prefix + "/forum/listThreads", forum.listThreads
app.get api_prefix + "/forum/listUsers", forum.listUsers

app.get api_prefix + "/thread/close", thread.close
app.get api_prefix + "/thread/create", thread.create
app.get api_prefix + "/thread/details", thread.details
app.get api_prefix + "/thread/list", thread.list
app.get api_prefix + "/thread/listPosts", thread.listPosts
app.get api_prefix + "/thread/open", thread.open
app.get api_prefix + "/thread/subscribe", thread.subscribe
app.get api_prefix + "/thread/unsubscribe", thread.unsubscribe
app.get api_prefix + "/thread/update", thread.update
app.get api_prefix + "/thread/vote", thread.vote

app.get api_prefix + "/post/create", post.create
app.get api_prefix + "/post/details", post.details
app.get api_prefix + "/post/list", post.list
app.get api_prefix + "/post/remove", post.remove
app.get api_prefix + "/post/restore", post.restore
app.get api_prefix + "/post/update", post.update
app.get api_prefix + "/post/vote", post.vote

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
  return

var express         = require('express');
var path            = require('path'); // модуль для парсинга пути
var app = express();

app.use(express.logger('dev')); // выводим все запросы со статусами в консоль
app.use(express.bodyParser()); // стандартный модуль, для парсинга JSON в запросах
app.use(express.methodOverride()); // поддержка put и delete
app.use(app.router); // модуль для простого задания обработчиков путей
app.use(express.static(path.join(__dirname, "public"))); // запуск статического файлового сервера, который смотрит на папку public/ (в нашем случае отдает index.html)

var mysql = require('mysql');
var pool  = mysql.createPool({
    host     : '127.0.0.1',
    user     : 'forum_api_user',
    password : 'forum_api_pswd'
});

app.get('/api', function (req, res) {
    pool.query('SELECT 1 + 1 AS solution', function(err, rows, fields) {
        if (err)
            throw err;

        var result = rows[0].solution;

        console.log('The solution is: ', result);
        res.send('The solution is: ' + result);
    });
});

app.listen(8084, function(){
    console.log('Express server listening on port 1337');
});
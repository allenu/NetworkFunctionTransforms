// Simple "blog post" server. See README.md for more details.

var express = require('express')
var app = express()
var bodyParser = require('body-parser')

var posts = []
for (var i=0; i < 5; i++) {
    posts.push({ Title: `Post ${i}`, Body: `Body of Post ${i}`, Delay: 0})
}

// Make post 1 take 2s and post 2 5s
posts[1].Delay = 2
posts[2].Delay = 5

// Posts 3 and 4 are special, so modify their titles
posts[3].Title = "Post 3: Will fake 500"
posts[4].Title = "Post 4: Will fake 404"

app.use(bodyParser.json())

app.use(function (req, res, next) {
    console.log("%s %s %s\n", Date.now().toString(), req.originalUrl, JSON.stringify(req.headers))
    next()
})

app.get('/api/list', function (req, res) {
    res.json(posts)
})

app.post('/api/write', function (req, res) {
    let blogPost = req.body
    // Modify it so we know server received it
    blogPost.Title += " (server)"
    blogPost.Body += " (server)"

    posts.push(blogPost)

    res.status(200)
    res.send(blogPost)
})

app.get('/api/read/:id', function (req, res) {
    let postId = parseInt(req.params["id"])

    if (postId == NaN) {
        res.status(400)
        res.send("400: Bad id specified\n")
    } else {
        if (postId >= 0 && postId < posts.length) {
            // For testing, make post delay some time based on delay attribute
            setTimeout( () => {
                // Special cases to fake errors
                if (postId == 3) {
                    res.status(500)
                    res.send("500: Internal server error\n")
                } else if (postId == 4) {
                    res.status(404)
                    res.send("404: Post not found\n")
                } else {
                    // Only include Title and Body in the returned post. Ignore any other
                    // properties (such as delay).
                    let post = posts[postId]
                    let returnedPost = {Title: post.Title, Body: post.Body}
                    res.json(returnedPost)
                }
            }, posts[postId].Delay * 1000)
        } else {
            res.status(404)
            res.send("404: Post not found\n")
        }
    }
})

app.get('/', function (req, res) {
	res.send('Make post requests at /api/read/{postId}')
})

var server = app.listen(3000, function () {
	var host = server.address().address
	var port = server.address().port

	console.log('Example app listening at http://%s:%s', host, port)
})

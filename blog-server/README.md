# blog-server

This is a simple service that hosts "blog posts". It's written in Node, but you don't
really need to know how it works internally. All you need to know is it provides two
simple endpoints for reading blog posts. One for listing all the posts:

    localhost:3000/api/list

And another for reading a specific post:

    localhost:3000/api/read/{postId}

where {postId} is the blog post to read. It will return a json "blog post" that has a Title and Body field.

Here's an example of a post it returns:

    {
        "Title": "Title of Post 0",
        "Body":  "Body of Post 0"
    }

Note that since this is meant for testing, the different postIds you provide will return different results and behaviors:

    0 ==> immediately returns blog post 0
    1 ==> returns blog post 1 after 2s delay
    2 ==> returns blog post 2 after 5s delay
    3 ==> causes 500 HTTP status response
    any other integer postId ==> 404 HTTP status
    any non-integer postId ==> 400 status

examples:

    http://localhost:3000/api/read/0
    http://localhost:3000/api/read/3
    http://localhost:3000/api/read/this-will-cause-400

The reason for the different behaviors above is to test various client scenarios where the client may
behave differently based on the type of response.

Note: use curl if you want to see the full HTTP response with headers include status code.

    curl -i http://localhost:3000/api/read/this-will-cause-400

# Installing and Running

To run it, be sure to have node v10 installed. You can install it via nvm:

    brew install nvm
    nvm install v10

Next, run npm to install the modules.

    npm install

Finally, you can run the server like so:

    npm start

Visit the page at http://localhost:3000.


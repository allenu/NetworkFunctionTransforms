
# Motivation:

- it's difficult to test UI scenarios with various network errors or various successful responses
- errors can take the form of network-level issues (timeouts, laggy requests, lost connections), server-side errors (server errors, various non-200
  HTTP codes), response body issues (JSON data returned may in an unexpected format)
- difficult to simulate such conditions in the mobile side
- possible to do on the server side, but limited to response errors or laggy resposes. can't simulate dropped connections or
  host not found issues, for instance

# Background and Initial Attempt

## First, we need to talk about how network calls are made

- URLSessionTasks take the form of
    - request
    - completionHandler

- completionHandler is the triplet of Data?, URLResponse?, Error?
  - based on your needs, you can attempt to look at Data first (assuming you expect a response body)
  - if it's not what you expect, treat it as an error and inspect URLResponse and Error for reasons why

- however, in general, it is always useful to know why a network request failed. this data can be used to
  - record analytics
  - decide if the network request failure was temporary and retry
  - decide if the mobile app should back off
  - determine if user is not signed in and needs to sign in again
  - etc.

- in other words, there should be a somewhat unified way to categorize the errors. to categorize the errors,
  one must analyze Data, URLResponse, Error in reverse order.
  - first look at Error. if it is non-nil, inspect it to see the nature of the error.
    - often this will be a URLError with an errorCode
  - if Error is non-nil, next inspect URLResponse
    - it should be non-nil (if not, it's quite unexpected)
    - it should also be an HTTPURLResponse (if not, it's unexpected)
    - next, take a look at the statusCode
    - in this case, the value of the status code in unexpected scenarios will generally be outside the 200
      range (typically a 400-level or 500-level code)
    - this status code is often specific to the type of request made, so should be handled separately from the Error
      conditions
  - finally, in the case of no Error or bad statusCode, we can attempt to parse the Data
  - should this fail, this is yet another type of error

In summary, lots of things can go wrong.


## Let's talk about the client side

- let's go back to the shape of the call

    task = dataTask(request, completionhandler)
    task.resume

- The completionhandler in the client is often long and needs to parse through the data. Often, it's easy to end up
  mixing the imperative code that decides how to handle the result of the response with the UI code that actually
  *acts* on this code. What I mean is you may end up with a lot of guards and checks on statuses and calls on the
  UI within the completion block.

  But it's really trying to do two things.

- Let's keep this in mind.

- So the goal:
  - make it so we can make a network call and deterministically cause a 500 status or a network timeout or other things

## Initial attempts to fake the network side

- initially, I wrote a server that always acted the same way
- next I thought, how do I get this in the app?

- my first naive thought was, let's fake the network layer
  - basically have something that takes the place of creating dataTasks

  - this seems like a good idea but then
    - I have to handle URLRequests (yuck)
    - I have to parse out the info in the URL manually

  - I have to fake URLSessionTask
    - two main things I'd have to handle
      - creating the task
      - resume()
      - cancel() (potentially)

- I thought, maybe not go that deep
  - what if I just fake the layer that creates the URLRequest
  - so if something is getting a blog post 1234,
    mock out the thing that creates the URL request with post 1234 in it
  - essentially, have

    func requestPost(postId: String, completionHandler: (data,response,error))

  - this seems okay, but now we have a postId, which is a high-level request coupled with a data,response,error, which
    is a very network-level response

- So let's step back further

    func requestPost(postId: String, completionHandler: (Post?))

  - so we'll have a layer that looks at the error, response and sees if they succeed. if so, it'll
    try to parse the data object.

  - this is nicer. now if it succeeds, Post is filled in.
  - if it fails, it's nil.

  - we can easily fake cases where Post is nil

- of course, we don't have an error returned... let's try this

    func requestPost(postId: String, completionhandler: (Post?, Data?, URLResponse?, Error?))

  - so if something goes wrong, Post will be nil and data,urlresponse,error will be provided
    so we can analyze them to see what went wrong.


- Still not great b/c while parsing to get Post, we *had* to analyze data,response,error anyway!

- We need a way to keep track of what went wrong and return it

    func requestPost(postId: String, completionHandler: (Post?, ErrorType?)

  - ErrorType may be an object that has info about the error with additional properties
    - like the URL
    - like the original Error object, if one

  - still, here it's an either-or proposition
    - either Post is non-nil and ErrorType is nil
    - or Post is nil and ErrorType is non-nil

- Okay, Swift let's us solve this with an enumerated type with values!

    enum Response {
        case hasPost(Post)
        case error(ErrorInfo)
    }

    func requestPost(postId: String, completionhandler: (Response) -> Void)

  - That's it. That's our solution!

  it may look like this:
    func requestPost(postId: String, completionhandler: (Response) -> Void) {
        let request = URLRequest(...)
        let task = session.dataTask(request, completionHandler: {data, response, error in
            // do logic here
            if let error = error {
                // do stuff
                response = .error(asdfasdf)
                completionhandler(.error(something))
            }
        })

  What's great is NOW we can create an object that just has all these funcs

    protocol BlogService {
    }

    protocol RemoteBlogService {
    }

  And then a mock one

    protocol MockBlogService {
        func requestPost(...) {
            DispatchQueue.main.async {
                completionhandler(.success)
            }
        }
    }

  But we can FAKE failure scenarios too!
    protocol MockBlogService {
        func requestPost(...) {
            DispatchQueue.main.async {
                if postId == 0 {
                    completionhandler(.success)
                } else if PostId == 1 {
                    completionHandler(.failure(.networkissue))
                }
            }
        }
    }

  This is great b/c we've essentially encoded the "meaning" of the response into an enum that we can decide
  things on in our UI separately. It's decoupled!

  We can swap it in when we want to do testing of the UI edge cases!

  Our UI can do this:

    .requesPost(...) { response in
        switch response {
            case .success(post):
                // Update UI

            case .failure(reason):
                // show alert
                // recover, etc.
        }
    }

# Benefits:

- Can now test UI edge cases.
- Can build a UI before the service is even written! If you are on separate teams, service-side team can build
  out the solution while you build out the UI.

- Even more, our completionhandler that takes d,r,e is JUST a function. it has no side-effects since
  it just converts the data to another type.

  this means we can easily unit test the conversion functions to make sure we've covered all of our bases

- Additionally, since we've decoupled the encoding of what the data,response,error mean from the rest of the UI logic,
  we have high confidence that the UI is correct when tested. we can test it against a mock and know that however
  the "response" was created doesn't matter. i.e. we dont' necessarily need to test the UI with a real network
  scenario where there is a timeout.

Lots of other benefits
- can log ALL types of errors in one place
- can retry as necessary on specific errors
- can back off in one way
- using enums mean your switches must be exhaustive -- catch type errors!

# Future work:

- currying?
- find a way to make this even more unified
  - templatize (?) the creation of the request and conversion of the response


# Let's review

- we wanted a way to mock out our network calls to test out edge cases in network failures
- by slowly and methodically working up from the lowest network request/response level, we found a suitable
  level to describe the request and response
- our final solution converts d,r,e into an enum
- this allows us incredible power to unit test each piece as well as mock out any service-side scenario we'd like

That's it. Thank you.


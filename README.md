
# Summary
A functional approach to handling network responses in Swift:

- There is a tendency to conflate how a UI responds to network requests simply because the API conventions make it the most obvious solution.
- The network response triplet of (Data?, URLResponse?, Error?) require specific processing to ultimately determine if the network request was successful and optionally extract the response from the HTTP body (data).
- This response-handling code is combined with UI processing code, which is messy and hard to scale to more scenarios.

## tl;dr

By making use of functions to transform the data to an appropriate client-level abstraction, we can simplify the form of the network requests and responses. As an added bonus, we can easily mock out the network behavior so that we can simulate very hard to reproduce
scenarios like long timeouts, bad HTTP response codes, and so on. Additionally, the function transforms are also easily unit-tested,
making for code that is overall more testable than alternatives.


# Background and Motivation

The original goals of this solution were to
- make network response handling more testable
  - unit tests where possible
- make it possible to mock out the network layer from a UI perspective

# Full Description
(This section is still a work in progress.)

We're separating giving meaning to the network response from the UI that reacts to it.

Why should you care?

- we can test things better
  - unit test the network handlers
  - UI test lots of edge cases we could not before
- we have way more freedom now to process the responses in various ways that are NOT tied together
  - UI can respond one way
  - logging can respond another
  - analytics can respond another

Each way we process the response has total freedom to do it however it pleases. We're not limited
by the if/else statements or other messy nested statements.

## Pros

- uses functional composition
- no classes or protocols to inherit
- everything is testable (see below)
- decouples UI from network response processing from network calling itself
  - UI can be tested independently of network layer
  - network layer is simply functions that do transformations, which are easily unit tested
- easily mock out specific network responses
- each type of network response can be 
- information hiding and contextual data only
  - enum response ONLY gives you the data you may need
  - if you get a failure case, you can dig in deeper as needed, or else not
  - no optionals in most cases. no need to do "if let"
- scales easily to more and more endpoints
- service "coordinator" that makes the requests on the network is super simple since it just 
  makes a request and in the completion handler transforms the data, response, and error into
  an enum.

- stuff that used to be in your network completionHandler is now in a unit-testable function
- the use of a Response enum is a "compile-time check". Using Data?, Response?, Error? on their
  own at the UI level leads to an infinite list of possibilities, themselves not testable.
  - using an enum means that if at a lower level we add a new error type and update the enum,
    the UI level is *forced* to handle it. Without this, if you used Data?, Response?, Error?
    in the UI level, you'd have to reason about new scenarios without compile-time checking.

## Potential Cons

- functional style may not appeal to all developers
- perhaps not a lot of code reuse
  - this can be improved simply by creating common Failure types over time


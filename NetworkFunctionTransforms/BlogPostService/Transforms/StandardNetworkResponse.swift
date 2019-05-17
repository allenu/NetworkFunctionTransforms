//
//  StandardNetworkResponse.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

// There are only two standard types of failures at the network level:
// - Error? was non-nil
// - URLResponse? was nil or was not an HTTPURLResponse
enum StandardNetworkFailureReason {
    // Scenarios where Error? was non-nil
    //
    // The initial list of items below is a small subset of URLErrors and is not meant to
    // be exhaustive. They're simply the most common scenarios that clients would care about
    // because they can react specifically to them. Other types of errors fall in the buckets
    // of urlError and genericError.
    case timeout
    case cannotConnectToHost
    case hostNotFound
    case requestCancelled
    case urlError(URLError)  // Catch-all for other URLErrors
    case genericError(Error) // Catch-all for cases where Error is non-nil and not a URLError type
    
    // Unexpected URLResponse? scenarios. These generally don't ever happen but are here
    // for completeness and in case something happens in the future to cause them to occur.
    case nilUrlResponse
    case nonHttpUrlResponse(URLResponse)
}

// A network response will either be a success or a failure. At this level, we do not look
// at the HTTP status code and determine if it's what we expected or not. That's up to whatever
// takes the success case to determine.
//
// Additional notes:
// - if a success, it is guaranteed to have an HTTPURLResponse and possibly data
// - if it fails, it will provide a reason for the failure
enum StandardNetworkResponse {
    case success(data: Data?, httpUrlResponse: HTTPURLResponse)
    case failure(reason: StandardNetworkFailureReason)
    
    init(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            if let urlError = error as? URLError {
                switch urlError.errorCode {
                case NSURLErrorTimedOut:
                    self = .failure(reason: .timeout)
                    
                case NSURLErrorCannotConnectToHost:
                    self = .failure(reason: .cannotConnectToHost)
                    
                case NSURLErrorCannotFindHost:
                    self = .failure(reason: .hostNotFound)
                    
                case NSURLErrorCancelled:
                    self = .failure(reason: .requestCancelled)
                    
                default:
                    self = .failure(reason: .urlError(urlError))
                }
            } else {
                self = .failure(reason: .genericError(error))
            }
            return
        }
        
        guard let response = response else {
            self = .failure(reason: .nilUrlResponse)
            return
        }
        
        guard let httpUrlResponse = response as? HTTPURLResponse else {
            self = .failure(reason: .nonHttpUrlResponse(response))
            return
        }
        
        self = .success(data: data, httpUrlResponse: httpUrlResponse)
    }
}

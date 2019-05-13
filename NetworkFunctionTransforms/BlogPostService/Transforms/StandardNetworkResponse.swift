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
    case success(httpUrlResponse: HTTPURLResponse, data: Data?)
    case failure(reason: StandardNetworkFailureReason)
    
    static func from(data: Data?, response: URLResponse?, error: Error?) -> StandardNetworkResponse {
        if let error = error {
            if let urlError = error as? URLError {
                switch urlError.errorCode {
                case NSURLErrorTimedOut:
                    return .failure(reason: .timeout)
                    
                case NSURLErrorCannotConnectToHost:
                    return .failure(reason: .cannotConnectToHost)
                    
                case NSURLErrorCannotFindHost:
                    return .failure(reason: .hostNotFound)
                    
                case NSURLErrorCancelled:
                    return .failure(reason: .requestCancelled)
                    
                default:
                    return .failure(reason: .urlError(urlError))
                }
            } else {
                return .failure(reason: .genericError(error))
            }
        }
        
        guard let response = response else {
            return .failure(reason: .nilUrlResponse)
        }
        
        guard let httpUrlResponse = response as? HTTPURLResponse else {
            return .failure(reason: .nonHttpUrlResponse(response))
        }
        
        return .success(httpUrlResponse: httpUrlResponse, data: data)
    }
}

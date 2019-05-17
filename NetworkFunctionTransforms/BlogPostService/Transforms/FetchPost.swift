//
//  FetchPost.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

//
// Request
//
struct PostJsonStruct: Codable {
    let title: String
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case body = "Body"
    }
}

struct FetchPostRequest: NetworkRequest {
    typealias networkResponse = FetchPostResponse
    
    let baseUrl: URL
    let postId: Int
    
    func toURLRequest() -> URLRequest {
        let url = baseUrl.appendingPathComponent("api/read/\(postId)")
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 4.0)
        request.httpMethod = "GET"
        return request
    }
}

//
// Response
//
enum FetchPostFailureReason {
    case standardNetworkFailure(reason: StandardNetworkFailureReason)
    
    // If a standard network failure isn't encountered, there may still be other
    // reasons why our fetch post request fails. These are specific to this type
    // of call.
    
    // All fetch post responses from the server have data. If it's missing, the server
    // did something bad.
    case missingData
    
    // The server returned data we did not expect. This would likely happen if the server
    // changed the contract and started responding with a new type of JSON body.
    case malformedData(Data)
    
    // The post requested doesn't exist.
    case missingPost
    
    // The server had some internal error (500 status). It's likely in a bad state and
    // should be called later.
    case serverError
    
    // The app made a bad request. This is very bad since it means the server is
    // expecting a new type of request we don't know about.
    case badRequest
    
    // Catch-all for other HTTP status codes that we didn't expect.
    case nonOkHttpStatusCode(httpUrlResponse: HTTPURLResponse)
}

// A fetch will either succeed or fail. If there's a failure, the failure
// reason can be analyzed and reacted to accordingly. If the fetch succeded,
// get the post from the success case.
enum FetchPostResponse: NetworkResponse {
    case success(post: PostJsonStruct)
    case failure(reason: FetchPostFailureReason)
    
    init(standardNetworkResponse: StandardNetworkResponse) {
        switch standardNetworkResponse {
        case .success(let data, let httpUrlResponse):
            self = FetchPostResponse(data: data, httpUrlResponse: httpUrlResponse)
            
        case .failure(let reason):
            self = .failure(reason: .standardNetworkFailure(reason: reason))
        }
    }
    
    init(data: Data?, httpUrlResponse: HTTPURLResponse) {
        let successStatusCode = httpUrlResponse.statusCode >= 200 && httpUrlResponse.statusCode < 300
        guard successStatusCode else {
            switch httpUrlResponse.statusCode {
            case 400:
                self = .failure(reason: .badRequest)
                
            case 404:
                self = .failure(reason: .missingPost)
                
            case 500:
                self = .failure(reason: .serverError)
                
            default:
                self = .failure(reason: .nonOkHttpStatusCode(httpUrlResponse: httpUrlResponse))
            }
            return
        }
        
        guard let data = data else {
            self = .failure(reason: .missingData)
            return
        }
        
        let decoder = JSONDecoder()
        
        if let post = try? decoder.decode(PostJsonStruct.self, from: data) {
            self = .success(post: post)
        } else {
            self = .failure(reason: .malformedData(data))
        }
    }

}

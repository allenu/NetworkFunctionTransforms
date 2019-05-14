//
//  AddPost.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/13/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

enum AddPostFailureReason {
    case standardNetworkFailure(reason: StandardNetworkFailureReason)
    
    case missingData
    case malformedData(Data)
    case missingPost
    case serverError
    case badRequest
    case nonOkHttpStatusCode(httpUrlResponse: HTTPURLResponse)
}

enum AddPostResponse {
    case success(post: PostJsonStruct)
    case failure(reason: AddPostFailureReason)
}

func createAddPostRequest(baseUrl: URL, post: PostJsonStruct) -> URLRequest {
    let url = baseUrl.appendingPathComponent("api/write/")
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 4.0)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let encoder = JSONEncoder()
    let data = try! encoder.encode(post)
    request.httpBody = data
    
    return request
}

func createAddPostResponse(data: Data?, response: URLResponse?, error: Error?) -> AddPostResponse {
    // First extract the standard response out and wrap the error if one is found. If no
    // error, construct a response from the data and httpUrlResponse.
    let standardNetworkResponse = StandardNetworkResponse.from(data: data, response: response, error: error)
    switch standardNetworkResponse {
    case .success(let httpUrlResponse, let data):
        return createAddPostResponse(data: data, httpUrlResponse: httpUrlResponse)
        
    case .failure(let reason):
        return .failure(reason: .standardNetworkFailure(reason: reason))
    }
}

func createAddPostResponse(data: Data?, httpUrlResponse: HTTPURLResponse) -> AddPostResponse {
    let successStatusCode = httpUrlResponse.statusCode >= 200 && httpUrlResponse.statusCode < 300
    guard successStatusCode else {
        switch httpUrlResponse.statusCode {
        case 400:
            return .failure(reason: .badRequest)
            
        case 404:
            return .failure(reason: .missingPost)
            
        case 500:
            return .failure(reason: .serverError)
            
        default:
            return .failure(reason: .nonOkHttpStatusCode(httpUrlResponse: httpUrlResponse))
        }
    }
    
    guard let data = data else {
        return .failure(reason: .missingData)
    }
    
    let decoder = JSONDecoder()
    
    if let post = try? decoder.decode(PostJsonStruct.self, from: data) {
        return .success(post: post)
    } else {
        return .failure(reason: .malformedData(data))
    }
}

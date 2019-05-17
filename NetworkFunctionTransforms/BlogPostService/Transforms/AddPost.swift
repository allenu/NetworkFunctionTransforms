//
//  AddPost.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/13/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

//
// Request
//
struct AddPostRequest: NetworkRequest {
    typealias networkResponse = AddPostResponse
    
    let baseUrl: URL
    let post: PostJsonStruct
    
    func toURLRequest() -> URLRequest {
        let url = baseUrl.appendingPathComponent("api/write/")
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 4.0)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let data = try! encoder.encode(post)
        request.httpBody = data
        
        return request
    }
}

//
// Response
//
enum AddPostFailureReason {
    case standardNetworkFailure(reason: StandardNetworkFailureReason)
    
    case missingData
    case malformedData(Data)
    case missingPost
    case serverError
    case badRequest
    case nonOkHttpStatusCode(httpUrlResponse: HTTPURLResponse)
}

enum AddPostResponse: NetworkResponse {
    case success(post: PostJsonStruct)
    case failure(reason: AddPostFailureReason)
    
    init(standardNetworkResponse: StandardNetworkResponse) {
        switch standardNetworkResponse {
        case .success(let data, let httpUrlResponse):
            self = AddPostResponse(data: data, httpUrlResponse: httpUrlResponse)
            
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

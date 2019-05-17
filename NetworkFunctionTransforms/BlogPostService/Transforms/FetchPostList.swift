//
//  FetchPostList.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

//
// Request
//
struct FetchPostListRequest: NetworkRequest {
    typealias networkResponse = FetchPostListResponse
    let baseUrl: URL
    
    func toURLRequest() -> URLRequest {
        let url = baseUrl.appendingPathComponent("api/list")
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 4.0)
        request.httpMethod = "GET"
        return request
    }
}

//
// Response
//
enum FetchPostListFailureReason {
    case standardNetworkFailure(reason: StandardNetworkFailureReason)
    case missingData
    case malformedData(Data)
    case serverError
    case nonOkHttpStatusCode(httpUrlResponse: HTTPURLResponse)
}

enum FetchPostListResponse: NetworkResponse {
    case success(posts: [PostJsonStruct])
    case failure(reason: FetchPostListFailureReason)
    
    init(standardNetworkResponse: StandardNetworkResponse) {
        switch standardNetworkResponse {
        case .success(let data, let httpUrlResponse):
            self = FetchPostListResponse(data: data, httpUrlResponse: httpUrlResponse)
            
        case .failure(let reason):
            self = .failure(reason: .standardNetworkFailure(reason: reason))
        }
    }

    init(data: Data?, httpUrlResponse: HTTPURLResponse) {
        let successStatusCode = httpUrlResponse.statusCode >= 200 && httpUrlResponse.statusCode < 300
        guard successStatusCode else {
            switch httpUrlResponse.statusCode {
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
        
        if let posts = try? decoder.decode([PostJsonStruct].self, from: data) {
            self = .success(posts: posts)
        } else {
            self = .failure(reason: .malformedData(data))
        }
    }
}

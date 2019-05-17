//
//  FetchPostList.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

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
    
    init(data: Data?, response: URLResponse?, error: Error?) {
        let standardNetworkResponse = StandardNetworkResponse.from(data: data, response: response, error: error)
        switch standardNetworkResponse {
        case .success(let httpUrlResponse, let data):
            self = createFetchPostListResponse(data: data, httpUrlResponse: httpUrlResponse)
            
        case .failure(let reason):
            self = .failure(reason: .standardNetworkFailure(reason: reason))
        }
    }
}

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

func createFetchPostListResponse(data: Data?, httpUrlResponse: HTTPURLResponse) -> FetchPostListResponse {
    let successStatusCode = httpUrlResponse.statusCode >= 200 && httpUrlResponse.statusCode < 300
    guard successStatusCode else {
        switch httpUrlResponse.statusCode {
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
    
    if let posts = try? decoder.decode([PostJsonStruct].self, from: data) {
        return .success(posts: posts)
    } else {
        return .failure(reason: .malformedData(data))
    }
}

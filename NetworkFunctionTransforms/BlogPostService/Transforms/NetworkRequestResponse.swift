//
//  NetworkRequestResponse.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/16/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

protocol NetworkResponse {
    init(standardNetworkResponse: StandardNetworkResponse)
}

protocol NetworkRequest {
    associatedtype networkResponse: NetworkResponse
    
    func toURLRequest() -> URLRequest
}

struct NetworkPerformer {
    let urlSession: URLSession

    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func dataTask<T: NetworkRequest>(request: T,
                                     completionHandler: @escaping (T.networkResponse) -> Void) -> URLSessionDataTask {
        let urlRequest = request.toURLRequest()
        let task = dataTask(urlRequest: urlRequest, completionHandler: { standardNetworkResponse in
            completionHandler(T.networkResponse(standardNetworkResponse: standardNetworkResponse))
        })
        return task
    }
    
    private func dataTask(urlRequest: URLRequest,
                  completionHandler: @escaping (StandardNetworkResponse) -> Void) -> URLSessionDataTask {
        let task = urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
            completionHandler(StandardNetworkResponse(data: data, response: response, error: error))
        })
        return task
    }
}

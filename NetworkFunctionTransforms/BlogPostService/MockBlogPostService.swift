//
//  MockBlogPostService.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//
//  This is an illustration of how you can mock out the server side responses without
//  having to write any network-level code (i.e. no URLRequests or URLSessionTasks).
//  Since the BlogPostService works with the request parameters (such as postId)
//  and the response enums (such as FetchPostResponse), each network response can
//  be faked simply by returning the appropriate enum case.

import Foundation

class MockBlogPostService: BlogPostService {
    static let posts: [PostJsonStruct] = [
        PostJsonStruct(title: "Fake post 0 title", body: "Fake post 0 body"),
        PostJsonStruct(title: "Fake post 1 title: 2s delay", body: "Fake post 1 body"),
        PostJsonStruct(title: "Fake post 2 title: timeout", body: "Fake post 2 body"),
        PostJsonStruct(title: "Fake post 3 title: 500", body: "Fake post 3 body"),
        PostJsonStruct(title: "Fake post 4 title: 404", body: "This will never be read"),
        PostJsonStruct(title: "Fake post 5 title: server down", body: "This will never be read"),
        PostJsonStruct(title: "Fake post 6 title: missing data", body: "This will never be read"),
        PostJsonStruct(title: "Fake post 7 title: bad data", body: "This will never be read"),
        PostJsonStruct(title: "Fake post 8 title: host not found", body: "This will never be read"),
        PostJsonStruct(title: "Fake post 9 title: request cancelled", body: "This will never be read"),
    ]
    
    func fetchPost(postId: Int, completionHandler: @escaping (FetchPostResponse) -> Void) {
        // Mock the fetch request by delaying 100ms and then calling the completionHandler.
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1, execute: {
            let response = MockBlogPostService.generateFetchPostResponse(for: postId)
            
            if postId == 1 {
                // Special case, post 1 has a 2s delay to help test UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    completionHandler(response)
                })
            } else {
                completionHandler(response)
            }
        })
    }
    
    func fetchPostList(completionHandler: @escaping (FetchPostListResponse) -> Void) {
        // To make this test more interesting, only respond after 2s
        let delay: TimeInterval = 2.0
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay, execute: {
            let response = MockBlogPostService.generateFetchPostListResponse()
            completionHandler(response)
        })
    }
    
    // Come up with a fake response for the given post requested.
    static func generateFetchPostResponse(for postId: Int) -> FetchPostResponse {
        let response: FetchPostResponse
        
        switch postId {
        case 0:
            let post = MockBlogPostService.posts[0]
            response = .success(post: post)
            
        case 1:
            let post = MockBlogPostService.posts[1]
            response = .success(post: post)
            
        case 2:
            response = .failure(reason: .standardNetworkFailure(reason: .timeout))
            
        case 3:
            response = .failure(reason: .serverError)
            
        case 4:
            response = .failure(reason: .missingPost)
            
        case 5:
            response = .failure(reason: .standardNetworkFailure(reason: .cannotConnectToHost))
            
        case 6:
            response = .failure(reason: .missingData)
            
        case 7:
            let data = "bad data".data(using: .utf8)!
            response = .failure(reason: .malformedData(data))
            
        case 8:
            response = .failure(reason: .standardNetworkFailure(reason: .hostNotFound))
            
        case 9:
            response = .failure(reason: .standardNetworkFailure(reason: .requestCancelled))
            
        default:
            fatalError("Not handled")
        }
        
        return response
    }
    
    static func generateFetchPostListResponse() -> FetchPostListResponse {
        return FetchPostListResponse.success(posts: MockBlogPostService.posts)
    }
}

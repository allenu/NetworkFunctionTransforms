//
//  RemoteBlogPostService.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

class RemoteBlogPostService: BlogPostService {
    var fetchPostTask: URLSessionDataTask?
    var fetchPostListTask: URLSessionDataTask?
    var addPostTask: URLSessionDataTask?
    let baseUrl = URL(string: "http://localhost:3000")!
    
    func fetchPost(postId: Int, completionHandler: @escaping (FetchPostResponse) -> Void) {
        if let fetchPostTask = fetchPostTask {
            fetchPostTask.cancel()
            self.fetchPostTask = nil
        }
        
        let request = createFetchPostRequest(baseUrl: baseUrl, postId: postId)
        fetchPostTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            let fetchPostResponse = createFetchPostResponse(data: data, response: response, error: error)
            completionHandler(fetchPostResponse)
        })
        fetchPostTask?.resume()
    }
    
    func fetchPostList(completionHandler: @escaping (FetchPostListResponse) -> Void) {
        if let fetchPostListTask = fetchPostListTask {
            fetchPostListTask.cancel()
            self.fetchPostListTask = nil
        }
        
        let request = createFetchPostListRequest(baseUrl: baseUrl)
        fetchPostListTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            let fetchPostListResponse = createFetchPostListResponse(data: data, response: response, error: error)
            completionHandler(fetchPostListResponse)
        })
        fetchPostListTask?.resume()
    }
    
    func addPost(post: PostJsonStruct, completionHandler: @escaping (AddPostResponse) -> Void) {
        if let addPostTask = addPostTask {
            addPostTask.cancel()
            self.addPostTask = nil
        }
        
        DispatchQueue.global().async {
            let request = createAddPostRequest(baseUrl: self.baseUrl, post: post)
            self.addPostTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                let addPostResponse = createAddPostResponse(data: data, response: response, error: error)
                completionHandler(addPostResponse)
            })
            self.addPostTask?.resume()
        }
    }
}

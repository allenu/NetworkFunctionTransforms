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
    
    let networkPerformer = NetworkPerformer(urlSession: URLSession.shared)
    
    func fetchPost(postId: Int, completionHandler: @escaping (FetchPostResponse) -> Void) {
        if let fetchPostTask = fetchPostTask {
            fetchPostTask.cancel()
            self.fetchPostTask = nil
        }

        let request = FetchPostRequest(baseUrl: baseUrl, postId: postId)
        fetchPostTask = networkPerformer.dataTask(request: request, completionHandler: completionHandler)
        fetchPostTask?.resume()
    }
    
    func fetchPostList(completionHandler: @escaping (FetchPostListResponse) -> Void) {
        if let fetchPostListTask = fetchPostListTask {
            fetchPostListTask.cancel()
            self.fetchPostListTask = nil
        }
        
        let request = FetchPostListRequest(baseUrl: baseUrl)
        fetchPostListTask = networkPerformer.dataTask(request: request, completionHandler: completionHandler)
        fetchPostListTask?.resume()
    }
    
    func addPost(post: PostJsonStruct, completionHandler: @escaping (AddPostResponse) -> Void) {
        if let addPostTask = addPostTask {
            addPostTask.cancel()
            self.addPostTask = nil
        }
        
        let request = AddPostRequest(baseUrl: baseUrl, post: post)
        addPostTask = networkPerformer.dataTask(request: request, completionHandler: completionHandler)
        addPostTask?.resume()
    }
    
}

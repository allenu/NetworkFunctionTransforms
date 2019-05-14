//
//  BlogPostService.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import Foundation

protocol BlogPostService {
    func fetchPost(postId: Int, completionHandler: @escaping (FetchPostResponse) -> Void)
    func fetchPostList(completionHandler: @escaping (FetchPostListResponse) -> Void)
    func addPost(post: PostJsonStruct, completionHandler: @escaping (AddPostResponse) -> Void)
}

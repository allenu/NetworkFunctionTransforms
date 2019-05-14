//
//  PostListViewController.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import UIKit

class PostListViewController: UITableViewController {
    let cellIdentifier = "Cell"
    var service: BlogPostService?
    var presentingPost: PostJsonStruct?
    var posts: [PostJsonStruct] = []
    var isFetchingList = true
    var nextPostId: Int = 0
    
    override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        let addBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(didTapAddButton(sender:)))
        navigationItem.rightBarButtonItem = addBarButtonItem

        fetchPostList()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFetchingList {
            return 1
        } else {
            return posts.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        let text: String
        if isFetchingList {
            text = "Please wait. Loading posts..."
        } else {
            text = posts[indexPath.row].title
        }
        cell.textLabel?.text = text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !isFetchingList {
            let postId = indexPath.row
            fetchPost(postId: postId)
        }
    }
    
    func fetchPost(postId: Int) {
        service?.fetchPost(postId: postId, completionHandler: { response in
            DispatchQueue.main.async {
                switch response {
                case .success(let post):
                    self.displayPost(post: post)
                    
                case .failure(let reason):
                    self.displayNetworkFailureAlert(for: reason)
                    
                    // NOTE: This is a good place to do logging or recording analytics regarding
                    // the failure response.
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPost" {
            if let postViewController = segue.destination as? PostViewController {
                postViewController.post = presentingPost
            }
        }
    }
    
    func fetchPostList() {
        service?.fetchPostList(completionHandler: { response in
            DispatchQueue.main.async {
                self.isFetchingList = false
                
                switch response {
                case .success(let posts):
                    self.posts = posts
                    
                case .failure(let reason):
                    var alertText = "Server error: we found no posts - \(reason)"
                    if case .standardNetworkFailure(let standardNetworkFailureReason) = reason {
                        if case .cannotConnectToHost = standardNetworkFailureReason {
                            alertText = "Server must be started. Go into the blog-server folder and view README.md for instructions."
                        }
                    }
                    
                    self.showAlert(text: alertText)
                }
                self.tableView.reloadData()
            }
        })
    }
    
    func displayPost(post: PostJsonStruct) {
        presentingPost = post
        performSegue(withIdentifier: "ShowPost", sender: self)
    }
    
    func displayNetworkFailureAlert(for failureReason: FetchPostFailureReason) {
        let alertText: String
        
        switch failureReason {
        case .malformedData(let data):
            alertText = "We couldn't parse the server data: \(data)"
            
        case .badRequest:
            alertText = "We made a bad request"
            
        case .missingData:
            alertText =  "Server isn't responding properly. No data."
            
        case .missingPost:
            alertText = "That post doesn't exist"
            
        case .serverError:
            alertText = "The server isn't responding correctly at the moment. You may want to try again later."
            
        case .nonOkHttpStatusCode(let httpUrlResponse):
            alertText = "Something is wrong with the server: \(httpUrlResponse)"
            
        case .standardNetworkFailure(let reason):
            switch reason {
            case .timeout:
                alertText = "The network is taking too long. You may want to try later when you have a better connection."
                
            case .cannotConnectToHost:
                alertText = "The server is down. :("
                
            default:
                alertText = "Something is wrong with the network: \(reason)"
            }
        }
        
        self.showAlert(text: alertText)
    }
    
    func showAlert(text: String) {
        let alertController = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func didTapAddButton(sender: Any) {
        let post = PostJsonStruct(title: "New Post \(nextPostId)", body: "Body: \(nextPostId)")
        nextPostId = nextPostId + 1
        service?.addPost(post: post, completionHandler: { response in
            DispatchQueue.main.async {
                switch response {
                case .success(let returnedPost):
                    self.posts.append(returnedPost)
                    self.tableView.reloadData()
                    
                case .failure(let reason):
                    self.showAlert(text: "We ran into an issue posting that: \(reason)")
                }
            }
        })
    }
}

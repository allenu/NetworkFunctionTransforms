//
//  TraditionalPostListViewController.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//
//  This is an example of how you'd typically handle network responses. This example
//  is given in contrast to PostListViewController. This "old way" of doing things
//  conflates the processing of the (Data?, URLResponse?, Error?) triplet with how
//  the UI responds, which affords fewer freedoms in how the response is processed
//  and is generally harder to read.

import UIKit

class TraditionalPostListViewController: UITableViewController {
    let cellIdentifier = "Cell"
    let baseUrl = URL(string: "http://localhost:3000")!
    var presentingPost: PostJsonStruct?
    var fetchPostTask: URLSessionDataTask?
    var fetchPostListTask: URLSessionDataTask?
    var posts: [PostJsonStruct] = []
    var isFetchingList = true

    override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
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
        
        let postId = indexPath.row
        fetchPost(postId: postId)
    }
    
    func fetchPostList() {
        let url = baseUrl.appendingPathComponent("api/list")
        fetchPostListTask = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                self.isFetchingList = false
                
                if error != nil {
                    self.showAlert(text: "Server must be started. Go into the blog-server folder and view README.md for instructions.")
                    return
                }
                
                guard let httpUrlResponse = response as? HTTPURLResponse else {
                    self.showAlert(text: "Unexpected response")
                    return
                }
                
                guard let data = data else {
                    self.showAlert(text: "Unexpected data")
                    return
                }
                
                guard httpUrlResponse.statusCode >= 200 && httpUrlResponse.statusCode < 300 else {
                    self.showAlert(text: "Server returned an error")
                    return
                }
                
                let decoder = JSONDecoder()
                if let posts = try? decoder.decode([PostJsonStruct].self, from: data) {
                    self.posts = posts
                    self.tableView.reloadData()
                } else {
                    self.showAlert(text: "Couldn't parse list of posts")
                }
            }
        })
        fetchPostListTask?.resume()
    }
    
    func fetchPost(postId: Int) {
        if let fetchPostTask = fetchPostTask {
            fetchPostTask.cancel()
            self.fetchPostTask = nil
        }
        
        let url = URL(string: "http://localhost:3000/api/read/\(postId)")
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 4.0)
        request.httpMethod = "GET"
        
        fetchPostTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    if let urlError = error as? URLError {
                        switch urlError.errorCode {
                        case NSURLErrorTimedOut:
                            self.showAlert(text: "The network is taking too long. You may want to try later when you have a better connection.")
                            
                        case NSURLErrorCannotConnectToHost:
                            self.showAlert(text: "The server is down. :(")
                            
                        default:
                            self.showAlert(text: "Something is wrong with the network: \(urlError)")
                        }
                    } else {
                        self.showAlert(text: "Something is wrong with the network: \(error)")
                    }
                    return
                }
                
                guard let httpUrlResponse = response as? HTTPURLResponse else {
                    self.showAlert(text: "Something is wrong with the network: response is not HTTPURLResponse")
                    return
                }
                
                guard let data = data else {
                    self.showAlert(text: "Server isn't responding properly. No data.")
                    return
                }
                
                let okStatus = httpUrlResponse.statusCode >= 200 && httpUrlResponse.statusCode < 300
                if okStatus {
                    let decoder = JSONDecoder()
                    if let post = try? decoder.decode(PostJsonStruct.self, from: data) {
                        self.displayPost(post: post)
                    } else {
                        self.showAlert(text: "We couldn't parse the server data: \(data)")
                    }
                } else {
                    switch httpUrlResponse.statusCode {
                    case 400:
                        self.showAlert(text: "We made a bad request")
                        
                    case 404:
                        self.showAlert(text: "That post doesn't exist")
                        
                    case 500:
                        self.showAlert(text: "The server isn't responding correctly at the moment. You may want to try again later.")
                        
                    default:
                        self.showAlert(text: "Something is wrong with the server: \(httpUrlResponse)")
                    }
                }
            }
        })
        
        fetchPostTask?.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPost" {
            if let postViewController = segue.destination as? PostViewController {
                postViewController.post = presentingPost
            }
        }
    }
    
    func displayPost(post: PostJsonStruct) {
        presentingPost = post
        performSegue(withIdentifier: "ShowPost", sender: self)
    }
    
    func showAlert(text: String) {
        let alertController = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

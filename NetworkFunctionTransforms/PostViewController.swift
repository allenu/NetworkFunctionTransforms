//
//  PostViewController.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    
    var post: PostJsonStruct?
    
    override func viewDidLoad() {
        guard let post = post else { return }
        
        titleLabel.text = post.title
        bodyTextView.text = post.body
    }
}

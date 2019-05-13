//
//  StartViewController.swift
//  NetworkFunctionTransforms
//
//  Created by Allen Ussher on 5/12/19.
//  Copyright © 2019 Ussher Press. All rights reserved.
//

import UIKit

class StartViewController: UITableViewController {
    let cellIdentifier = "Cell"
    let rows = [
        "Functional Transform w/Remote Calls",
        "Functional Transform w/Mocked Calls",
        "Non-Functional Transform Old Way"
    ]
    let showFunctionalSegueIdentifier = "ShowFunctional"
    let showOldWaySegueIdentifier = "ShowOldWay"
    var useMockService = false
    
    override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        cell.textLabel?.text = rows[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segueIdentifier: String
        switch indexPath.row {
        case 0, 1:
            useMockService = indexPath.row == 1
            segueIdentifier = showFunctionalSegueIdentifier
            
        case 2:
            segueIdentifier = showOldWaySegueIdentifier
            
        default:
            fatalError("Not defined")
        }
        
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier  == showFunctionalSegueIdentifier {
            let postListViewController = segue.destination as! PostListViewController
            postListViewController.service = useMockService ? MockBlogPostService() : RemoteBlogPostService()
        }
    }
}

//
//  HTPGitUsersViewController.swift
//  HomeTask
//
//  Created by Semen Martiushev on 8/21/16.
//  Copyright © 2016 Semen Martiushev. All rights reserved.
//

import UIKit

let kHTPGitUsersViewControllerElementsAtPage: Int = 20
private var g_imageCache = [String:UIImage]()


class HTPGitUsersViewController: UITableViewController {

var urlRequest: NSMutableURLRequest? = nil;

    override func viewDidLoad() {
        super.viewDidLoad()
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        _allUsers = nil
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    var once: dispatch_once_t = 0;
    private var _allUsers: Dictionary<Int,Dictionary<String, String>>?
    private var _usersInfoIsLoading = false
    func filteredUser(index: Int) -> Dictionary<String, String>? {
        
        var resultInfo: Dictionary<String,String>? = nil
        if nil == _allUsers && !_usersInfoIsLoading
        {
            _usersInfoIsLoading = true
            
            
            if nil == self.urlRequest
            {
                // Not realy need {
                let server: OCTServer = OCTServer.dotComServer()
                let user: OCTUser = OCTUser(rawLogin:"smartiushev", server:server)
                let client: OCTClient = OCTClient.unauthenticatedClientWithUser(user)
                // }
                self.urlRequest = client.requestWithMethod("GET", path: "users", parameters:["per_page" : 100], notMatchingEtag: nil) // Always fetch latest data
            }
            
            let connection :NSURLSession =  NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let dataTask: NSURLSessionDataTask = connection.dataTaskWithRequest(self.urlRequest!) { (data: NSData?, responce: NSURLResponse?, error: NSError?) -> Void in
                if responce?.MIMEType == "application/json"
                {
                    var json: Array<AnyObject>!
                    do {
                        json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? Array
                    } catch {
                        print(error)
                    }
                
                    var allUsers: Dictionary<Int,Dictionary<String, String>> = [:]
                    var i: Int! = 0
                    for dictionary in json {
                        var dict = dictionary as? [String : AnyObject]
                        var userInfo: Dictionary<String, String>! = [:]
                        userInfo["login"] = dict!["login"] as? String
                        userInfo["avatar_url"] = dict!["avatar_url"] as? String
                        userInfo["html_url"] = dict!["html_url"] as? String
                        userInfo["followers_url"] = dict!["followers_url"] as? String
                        
                        allUsers[i] = userInfo
                        i = i+1
                    }
                    self._allUsers = allUsers
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        if let indexPaths = self.tableView.indexPathsForVisibleRows
                        {
                            self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.None)
                        }
                    })
                }
            }
            dataTask.resume()
        }
        
        resultInfo = self._allUsers != nil ? self._allUsers![index] : nil;
        
        return (resultInfo != nil) ? resultInfo!: ["no name":"no name"]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("kHTPUserRowIdentifier", forIndexPath: indexPath)
        
        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil

        if let userRow = self.filteredUser(indexPath.row)
        {
            if let text = userRow["login"]
            {
                cell.textLabel?.text = text
            }
            if let text = userRow["html_url"]
            {
                cell.detailTextLabel?.text = text
            }
            
            if let urlString = userRow["avatar_url"]
            {
                let imageURL = NSURL(string: urlString)
                
                if let img = g_imageCache[urlString]
                {
                    cell.imageView?.image = img
                }
                else
                {
                    let task: NSURLSessionDataTask = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()).dataTaskWithURL(imageURL!, completionHandler: { (data, responce, error) in
                        let image = UIImage(data: data!)
                        g_imageCache[urlString] = image
                        dispatch_async(dispatch_get_main_queue(), {
                            if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath)
                            {
                                cellToUpdate.imageView?.image = image
                                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                            }
                        })
                    })
                    task.resume()
                }
            }
        }
        
        return cell
    }
 
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    
        return 100.0
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "kHTPGetFollowersSegueIdentifier"
        {
            if let gitUsersVC = segue.destinationViewController as? HTPGitUsersViewController
            {
                if let cell = sender as? UITableViewCell
                {
                    if let index = self.tableView.indexPathForCell(cell)?.row
                    {
                        if let userRow = self.filteredUser(index)
                        {
                            if let url = NSURL(string: userRow["followers_url"]!)
                            {
                                gitUsersVC.urlRequest = NSMutableURLRequest(URL: url)
                            }
                        }
                    }
                }
                
            }

        }
    }
}

//
//  HTPGitUsersViewController.swift
//  HomeTask
//
//  Created by Semen Martiushev on 8/21/16.
//  Copyright © 2016 Semen Martiushev. All rights reserved.
//

import UIKit

let kHTPGitUsersViewControllerElementsAtPage: Int = 10

private var g_imageCache = [String:UIImage]()

var pageToETag = [Int:String]()
var pageToUsers = [Int:Array<Dictionary<String,String>>]()
var pageIsLoading = [Int:Bool]()

var connection :NSURLSession? = nil

class HTPGitUsersViewController: UITableViewController {

var urlRequestPath: String? = nil;
var parameters = [NSObject:AnyObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        _allUsers = [Int:Array<Dictionary<String, AnyObject>>]()
    }

    // MARK: - Table view data source
    
    private var _allUsers = [Int:Array<Dictionary<String, AnyObject>>]()
    func loadUsers(page: Int, completion:(users: Array<Dictionary<String,AnyObject>>?) -> Void) -> Void
    {
        let server: OCTServer = OCTServer.dotComServer()
        let user: OCTUser = OCTUser(rawLogin:"smartiushev", server:server)
        let client: OCTClient = OCTClient.unauthenticatedClientWithUser(user)
        if nil == self.urlRequestPath
        {
            self.urlRequestPath = "users"
        }
        
        // TODO: rewrite
        if self.urlRequestPath == "users"
        {
            if page > 0
            {
                if let userInfos = _allUsers[page - 1]
                {
                    if let userInfo = userInfos.last
                    {
                        if let last_id = userInfo["id"] as? Int
                        {
                            self.parameters = ["per_page" : kHTPGitUsersViewControllerElementsAtPage, "since" : last_id]
                        }
                    }
                }
            }
            else
            {
                self.parameters = ["per_page" : kHTPGitUsersViewControllerElementsAtPage, "since" : "0"]
            }
        }
        else
        {
            self.parameters = ["per_page" : kHTPGitUsersViewControllerElementsAtPage, "page" : page + 1]
        }
        
        
        let urlRequest: NSURLRequest = client.requestWithMethod("GET", path: urlRequestPath, parameters:parameters, notMatchingEtag: pageToETag[page]) // Fetch new elements for page if needed
        if nil == connection
        {
            connection = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        }
        
        let dataTask: NSURLSessionDataTask = connection!.dataTaskWithRequest(urlRequest) { (data: NSData?, responce: NSURLResponse?, error: NSError?) -> Void in
            if data?.length > 0 && responce?.MIMEType == "application/json"
            {
                var json: Array<AnyObject>!
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? Array
                } catch {
                    print(error)
                }
                
                // Store ETag for next page request
                if let urlResponse = responce as? NSHTTPURLResponse
                {
                    pageToETag[page] = urlResponse.allHeaderFields["Etag"] as? String
                }
                
            
                var newUsers = [Dictionary<String, AnyObject>]()
                for dictionary in json {
                    var dict = dictionary as? [String : AnyObject]
                    var userInfo: Dictionary<String, AnyObject>! = [:]
                    userInfo["login"] = dict!["login"] as? String
                    userInfo["avatar_url"] = dict!["avatar_url"] as? String
                    userInfo["html_url"] = dict!["html_url"] as? String
                    userInfo["followers_url"] = dict!["followers_url"] as? String
                    userInfo["id"] = dict!["id"] as? Int
                    
                    newUsers.append(userInfo)
                }
                
                completion(users: newUsers)
            }
            else
            {
                completion(users: nil)
            }
        }
        dataTask.resume()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    var once: dispatch_once_t = 0;
    
    
    func filteredUser(index: Int) -> Dictionary<String, AnyObject>? {
        
        var resultInfo: Dictionary<String,AnyObject>? = nil
        
        let page: Int = (index / kHTPGitUsersViewControllerElementsAtPage)
        
        if nil == pageIsLoading[page]
        {
           pageIsLoading[page] = false
        }
        
        if !pageIsLoading[page]!
        {
            pageIsLoading[page] = true
            self.loadUsers(page) { (users) in
                if let newUsers = users
                {
                    if !newUsers.isEmpty
                    {
                        if nil == self._allUsers[page]
                        {
                            self._allUsers[page] = newUsers
                        }
                        else
                        {
                            self._allUsers[page]!.appendContentsOf(newUsers)
                            // sort ?
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        if nil != self.tableView.superview
                        {
                            if let indexPaths = self.tableView.indexPathsForVisibleRows
                            {
                                self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.None)
                            }
                        }
                    })
                }
                pageIsLoading[page] = false
            }
        }
        
        if let users = self._allUsers[page]
        {
            if users.count > (index - page * kHTPGitUsersViewControllerElementsAtPage)
            {
                resultInfo = users[index - page * kHTPGitUsersViewControllerElementsAtPage]
            }
        }
        
        return (resultInfo != nil) ? resultInfo!: ["":""]
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("kHTPUserRowIdentifier", forIndexPath: indexPath)
        
        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        cell.accessoryType = UITableViewCellAccessoryType.None;

        if let userRow = self.filteredUser(indexPath.row)
        {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            if let text = userRow["login"] as? String
            {
                cell.textLabel?.text = text
            }
            if let text = userRow["html_url"] as? String
            {
                cell.detailTextLabel?.text = text
            }
            
            if let urlString = userRow["avatar_url"] as? String
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
                            if nil != tableView.superview
                            {
                                if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath)
                                {
                                    cellToUpdate.imageView?.image = image
                                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                                }
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
                    if let login = cell.textLabel?.text
                    {
                        gitUsersVC.urlRequestPath = "users/\(login)/followers"
                    }
                }
            }
        }
    }
}

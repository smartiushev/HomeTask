//
//  HTPGitUsersViewController.swift
//  HomeTask
//
//  Created by Semen Martiushev on 8/21/16.
//  Copyright © 2016 Semen Martiushev. All rights reserved.
//

import UIKit

class HTPGitUsersViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "reuseIdentifier")


        let server: OCTServer = OCTServer.dotComServer()
        let user: OCTUser = OCTUser(rawLogin:"smartiushev", server:server)
        let client: OCTClient = OCTClient.unauthenticatedClientWithUser(user)
        //RACSignal *request = client.fetchUserRepositories()
        
        
        
        let urlRequest: NSMutableURLRequest = client.requestWithMethod("GET", path: "users/defunkt?per_page=1/~{id, login, url, avatar_url}", parameters: nil, notMatchingEtag: nil) // Always fetch latest data
        let connection :NSURLSession =  NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let dataTask: NSURLSessionDataTask = connection.dataTaskWithRequest(urlRequest) { (data: NSData?, responce: NSURLResponse?, error: NSError?) -> Void in
            if responce?.MIMEType == "application/json"
            {
                let jsonCollection: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers)
                NSLog("asdfasdf")
            }
        }
        dataTask.resume()
        
//        let url: NSURL? = NSURL(string:"https://api.github.com/users/defunkt")
//        dataTask = connection.dataTaskWithURL(url!, completionHandler: { (data: NSData?, responce: NSURLResponse?, error: NSError?) -> Void in
//            NSLog("asdfasdf")
//        })
//        dataTask.resume()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }

    var once: dispatch_once_t = 0;
    private var _allUsers: Array<String>!
    func filteredUser(index: Int) -> String {
        if nil == _allUsers
        {
            dispatch_once(&once, {
                let server: OCTServer = OCTServer.dotComServer()
                let user: OCTUser = OCTUser(rawLogin:"smartiushev", server:server)
                let client: OCTClient = OCTClient.unauthenticatedClientWithUser(user)
                let urlRequest: NSMutableURLRequest = client.requestWithMethod("GET", path: "users?per_page=25", parameters: nil, notMatchingEtag: nil) // Always fetch latest data
                let connection :NSURLSession =  NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
                let dataTask: NSURLSessionDataTask = connection.dataTaskWithRequest(urlRequest) { (data: NSData?, responce: NSURLResponse?, error: NSError?) -> Void in
                    if responce?.MIMEType == "application/json"
                    {
                        var json: Array<AnyObject>!
                        do {
                            json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? Array
                        } catch {
                            print(error)
                        }
                    
                        var mutableUsers = Array<String>()
                        for dictionary in json {
                        
                            
                            let dict = dictionary as? [String : AnyObject]
                            if let userName: String = dict!["login"] as? String
                            {
                                mutableUsers.append(userName)
                            }
                        }

                        self._allUsers = mutableUsers
                    }
                }
                dataTask.resume()
            })
        }
        
        return (self._allUsers != nil) ? self._allUsers[index]: "no name"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        cell.textLabel?.text = self.filteredUser(indexPath.row)

        return cell
    }
 
    

    // MARK: - Navigation

}

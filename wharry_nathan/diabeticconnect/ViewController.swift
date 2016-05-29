//
//  ViewController.swift
//  diabeticconnect
//
//  Created by Nathan Wharry on 5/12/16.
//  Copyright © 2016 Nathan Wharry. All rights reserved.
//

import UIKit
import CareKit
import ResearchKit

class ViewController: UIViewController {
    

    // outlets for the login fields
    @IBOutlet var userName: UITextField!
    @IBOutlet var passWord: UITextField!
    
    // action for the login button
    @IBAction func loginBtn(sender: AnyObject) {
        
        // verify fields are filled before trying to validate
        if ((userName.text! == "") || (passWord.text! == "")) {
            
            // setup alertcontroller to inform user to fill in all login fields
            
            //Create the AlertController
            let loginAlertController: UIAlertController = UIAlertController(title: "Login Error", message: "You must enter a username and password before proceeding", preferredStyle: .Alert)
            
            // add the OK button
            let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            loginAlertController.addAction(confirmAction)
                
            // call login alert
            self.presentViewController(loginAlertController, animated: true, completion: nil)

            
        } else {
            
            // assign variables
            let username = userName.text!
            let password = passWord.text!.sha1() // encrypt password to validate database
            
            // query the database
            let userInfo = SD.executeQuery("SELECT * FROM Users WHERE UserName = ?", withArgs: [username])
            
            if userInfo.error == nil {
                
                if userInfo.result.count == 0 {
                    
                    // no username found
                    //Create the AlertController
                    let loginAlertController: UIAlertController = UIAlertController(title: "Login Unsuccessful", message: "Username Not Found.\nPlease Try Again.", preferredStyle: .Alert)
                    
                    // add the OK button
                    let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    loginAlertController.addAction(confirmAction)
                    
                    // call login alert
                    self.presentViewController(loginAlertController, animated: true, completion: nil)
                    
                } else {
                    
                    // validate password
                    if password == userInfo.result[0]["Password"]?.asString() {
                        
                        // set the Care Plan Store folder for user
                        loggedUserPath = username + password[0...7]
                        
                        // call the segue to start the app
                        performSegueWithIdentifier("loginSegue", sender: nil)
                        
                    } else {
                        
                        // incorrect password
                        //Create the AlertController
                        let loginAlertController: UIAlertController = UIAlertController(title: "Login Unsuccessful", message: "Incorrect Password.\nPlease Try Again.", preferredStyle: .Alert)
                        
                        // add the OK button
                        let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                        loginAlertController.addAction(confirmAction)
                        
                        // call login alert
                        self.presentViewController(loginAlertController, animated: true, completion: nil)
                        
                    }
                }
                
            } else {
                
                //Create the AlertController
                let loginAlertController: UIAlertController = UIAlertController(title: "Login Unsuccessful", message: "You have entered an incorrect username/password combination.\nPlease Try Again.", preferredStyle: .Alert)
                
                // add the OK button
                let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                loginAlertController.addAction(confirmAction)
                
                // call login alert
                self.presentViewController(loginAlertController, animated: true, completion: nil)
                
            }
        }
    }
    
    // function to test if the table has been created (namely has the user created an account yet)
    override func viewDidAppear(animated: Bool) {
        
        // create the database and table if not currently present while checking for an account        
        if userTable() == false {
            
            //Create the AlertController to create an initial account
            let loginAlertController: UIAlertController = UIAlertController(title: "Create an Account", message: "You will first need to create an account to use this application", preferredStyle: .Alert)
            
            // add the OK button
            let confirmAction: UIAlertAction = UIAlertAction(title: "Create Account", style: .Cancel, handler: { (action) in
                self.performSegueWithIdentifier("createAccountSegue", sender: nil)
            })
            
            loginAlertController.addAction(confirmAction)
            
            // call login alert
            presentViewController(loginAlertController, animated: true, completion: nil)
            
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func homeScreenSegue(segue: UIStoryboardSegue) {
    
        // empty the login fields when returning to screen
        userName.text = ""
        passWord.text = ""
    
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loginSegue" {
            
            if loggedOut == true {
                
                let searchPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
                let applicationSupportPath = searchPaths[0] + "/\(loggedUserPath)"
                let persistenceDirectoryURL = NSURL(fileURLWithPath: applicationSupportPath)
                
                if !NSFileManager.defaultManager().fileExistsAtPath(persistenceDirectoryURL.absoluteString, isDirectory: nil) {
                    try! NSFileManager.defaultManager().createDirectoryAtURL(persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                // Create the store.
                let newStore = OCKCarePlanStore(persistenceDirectoryURL: persistenceDirectoryURL)
                
                // grab the viewController
                let navVC = segue.destinationViewController as! UINavigationController
                let careCardVC = navVC.topViewController as! RootViewController
                
                careCardVC.storeManager.store = newStore
                
            }
        }
    }


}


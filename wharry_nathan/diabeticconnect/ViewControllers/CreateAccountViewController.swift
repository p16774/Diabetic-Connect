//
//  CreateAccountViewController.swift
//  wharry_nathan
//
//  Created by Nathan Wharry on 5/21/16.
//  Copyright © 2016 Nathan Wharry. All rights reserved.
//

import UIKit

class CreateAccountViewController: UIViewController {

    @IBOutlet var fullName: UITextField!
    @IBOutlet var userName: UITextField!
    @IBOutlet var passWord: UITextField!
    @IBOutlet var birthDate: UIDatePicker!
    
    
    // test function to help with the testing the build correctly (will be removed upon completion)
    @IBAction func clearTable(sender: AnyObject) {
        
        if let err = SD.deleteTable("Users") {
            print(err)
        } else {
            print("Users Cleared Successfully!")
        }
        
    }
    
    
    @IBAction func createAccountBtn(sender: AnyObject) {
        
        // test for empty fields first
        if ((self.fullName.text?.isEmpty ?? true) || (self.userName.text?.isEmpty ?? true) || (self.passWord.text?.isEmpty ?? true)) {
            
            //Create the AlertController
            let accountCreateController: UIAlertController = UIAlertController(title: "Empty Fields", message: "Please fill in all fields", preferredStyle: .Alert)
            
            // add the OK button
            let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            accountCreateController.addAction(confirmAction)
            
            // call login alert
            self.presentViewController(accountCreateController, animated: true, completion: nil)
        
        } else if ((self.fullName.text?.isEmpty ?? false) || (self.userName.text?.isEmpty ?? false) || (self.passWord.text?.isEmpty ?? false) || (birthDate.date.format() == NSDate().format())) {
            
            //Create the AlertController
            let accountCreateController: UIAlertController = UIAlertController(title: "Empty BirthDate", message: "Please enter your birthdate.", preferredStyle: .Alert)
            
            // add the OK button
            let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            accountCreateController.addAction(confirmAction)
            
            // call login alert
            self.presentViewController(accountCreateController, animated: true, completion: nil)
            
        } else {
            
            // cast the data fields to variables (since we've validated there's data already we can safely force unwrap)
            let fullname = fullName.text!
            let username = userName.text!
            let password = passWord.text!.sha1() // encrypting password before storing in database
            let birthday = birthDate.date.format()
            
            // create the database and table if not currently present while checking for an account
            if userTable() == false {
                
               // create table
                if let err = SD.createTable("Users", withColumnNamesAndTypes: ["Name": .StringVal, "UserName": .StringVal, "Password": .StringVal, "BirthDate": .DateVal]) {
                    
                    //there was an error during this function, handle it here
                    print("Error Created Table \n Error: \(err)")
                    
                } else {
                    
                    // insert the user info
                    if let err = SD.executeChange("INSERT INTO Users (Name, UserName, Password, BirthDate) VALUES (?, ?, ?, ?)", withArgs: [fullname, username, password, birthday]) {
                        //there was an error during the insert, handle it here
                        print(err)
                    } else {
                        print("data entered successfully")
                        performSegueWithIdentifier("careCardSegue", sender: nil)
                    }
                }
                
            } else {
                
                // insert the user info
                if let err = SD.executeChange("INSERT INTO Users (Name, UserName, Password, BirthDate) VALUES (?, ?, ?, ?)", withArgs: [fullname, username, password, birthday]) {
                    //there was an error during the insert, handle it here
                    print(err)
                } else {
                    print("data entered successfully")
                    performSegueWithIdentifier("careCardSegue", sender: nil)
                }
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // create gesture for tapping the screen and then call dismissKeyboard function
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CreateAccountViewController.dismissKeyboard))
        
        // add gesture to the current view
        view.addGestureRecognizer(tap)
        
        // configure date picker
        //birthDate.setValue(<#T##value: AnyObject?##AnyObject?#>, forKey: <#T##String#>)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // dismissKeyboard function called when the tap gesture is recognized
    func dismissKeyboard() {
        // endEditing called true on tap gesture
        view.endEditing(true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

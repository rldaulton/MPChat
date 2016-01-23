//
//  ChatFeed.swift
//  Chatter
//
//  Created by Ryan Daulton on 12/11/15.
//  Copyright © 2015 Fade LLC. All rights reserved.
//


import UIKit
import CoreData
import Foundation
import MultipeerConnectivity

class ChatFeed: UIViewController{
    
    @IBAction func Sendit(sender: AnyObject) {
        sendThought()
    }
    @IBOutlet var textEntry: UITextField!
    @IBOutlet var chatFeedTbl: UITableView!
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    
    var isSending = false
    let chatterBoxClient = MultiPeerConnectivityManager.sharedInstance()
    var messages = [String:String]()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var managedContext: NSManagedObjectContext?
    var globalMess: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardNotification:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadList:",name:"load", object: nil)
        
        
        // Do any additional setup after loading the view, typically from a nib.
        managedContext = self.appDelegate.managedObjectContext!
        LoadMessagesFeed()
        
    }
    func LoadMessagesFeed() {
        // Fetch Messages
        chatterBoxClient.messagesTable.removeAll(keepCapacity: true)
        let MessRequest = NSFetchRequest(entityName: "Feed")
        var error: NSError? = nil
        let MessResults = (try! managedContext!.executeFetchRequest(MessRequest)) as! [Feed]
        if MessResults.count > 1 {
            for message in MessResults {
                chatterBoxClient.messagesTable.append(message.messages)
            }
        }
        print(chatterBoxClient.messagesTable)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            let duration:NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            self.keyboardHeightLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            UIView.animateWithDuration(duration,
                delay: NSTimeInterval(0),
                options: animationCurve,
                animations: { self.view.layoutIfNeeded() },
                completion: nil)
        }
    }
    
    func loadList(notification: NSNotification){
        //load data here
        self.chatFeedTbl.reloadData()
    }
    
    func sendThought() {
        let textToSend = textEntry.text
        if textToSend != "" {
            chatterBoxClient.stopAdvertizing()
            chatterBoxClient.myMessage(textToSend!)
            self.chatterBoxClient.startAdvertizing()
            
            /*
            delay(seconds: 1.0) { () -> () in
            self.chatterBoxClient.startAdvertizing()
            }
            */
            
            //      print("Sending: \(textToSend)")
            isSending = true
            self.textEntry.resignFirstResponder()
            
        } else {
            self.textEntry.resignFirstResponder()
        }
        
    }
    
    
    func eraseAllCore(){
        //ERASE ALL CORE DATA
        /*
        let context1 = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        // fetch request on your entity
        let fetchRequest1 = NSFetchRequest(entityName: "Feed")
        var error3 : NSError?
        
        // execute fetch request
        do {
        if let fetchResults = try context1.executeFetchRequest(fetchRequest1) as? [Feed] {
        if error3 != nil{
        return
        }
        
        // if results are found
        if fetchResults.count != 0 {
        
        // assign number of results to "i"
        var i = fetchResults.count
        
        //START LOOP
        for i ; i != 0 ; i-- {
        
        //delete one result per time
        let delete = fetchResults[i - 1]
        context1.deleteObject(delete)
        do {
        try context1.save()
        print("Entry Deleted")
        } catch let error1 as NSError {
        error3 = error1
        print("Could not delete \(error3), \(error3!.userInfo)")
        
        }//END LOOP
        }
        }
        }
        }catch{
        print("Dim background error \(error3)")
        }
        
        */
        let fetchRequest = NSFetchRequest(entityName: "Feed")
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try managedContext!.executeRequest(deleteRequest)
            } catch let error as NSError {
                // TODO: handle the error
            }
        } else {
            // Fallback on earlier versions
        }
        
        
    }
    
}
// MARK: - Global Functions

// A delay function
func delay(seconds seconds: Double, completion:()->()) {
    let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64( Double(NSEC_PER_SEC) * seconds ))
    
    dispatch_after(popTime, dispatch_get_main_queue()) {
        completion()
    }
}

// MARK: UIColor from web hex value
func hexStringToUIColor(hex:String) -> UIColor {
    var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
    
    if (cString.hasPrefix("#")) {
        cString = cString.substringFromIndex(cString.startIndex.advancedBy(1))
    }
    
    if (cString.characters.count != 6) {
        return UIColor.grayColor()
    }
    
    var rgbValue:UInt32 = 0
    NSScanner(string: cString).scanHexInt(&rgbValue)
    
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}



// MARK: MultiPeerConnectivityManager Delegate
extension ChatFeed: MultiPeerConnectivityManagerDelegate {
    func addMessage(id: String, message: String, name: String?) {
        if messages[id] == nil {
            //      println("Adding Message...")
            var fullMessage = message
            if name != nil && name != "" {
                fullMessage = message.stringByAppendingString("\n - \(name!)")
            }
            messages.updateValue(fullMessage, forKey: id)
            //floatLeft(id)
            // print("Messages Array: \(messages)")
        }
    }
    
    func removeMessage(id: String) {
        //    println("Removing Message: \(id)")
        messages.removeValueForKey(id)
    }
    
}



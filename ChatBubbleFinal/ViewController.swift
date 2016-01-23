//
//  ViewController.swift
//  ChatBubbleFinal
//
//  Created by Sauvik Dolui on 02/09/15.
//  Copyright (c) 2015 Innofied Solution Pvt. Ltd. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import MultipeerConnectivity

class ViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var messageComposingView: UIView!
    @IBOutlet weak var messageCointainerScroll: UIScrollView!
    @IBOutlet weak var buttomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var BottomComposeViewLayoutConstraint: NSLayoutConstraint!
    
    
    var selectedImage : UIImage?
    var lastChatBubbleY: CGFloat = 10.0
    var internalPadding: CGFloat = 8.0
    var lastMessageType: BubbleDataType?
    
    var imagePicker = UIImagePickerController()
    var isSending = false
    let chatterBoxClient = MultiPeerConnectivityManager.sharedInstance()
    var messages = [String:String]()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var managedContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        managedContext = self.appDelegate.managedObjectContext!
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadList:",name:"load", object: nil)

        imagePicker.delegate = self
        imagePicker.allowsEditing = false //2
        imagePicker.sourceType = .PhotoLibrary //3
        sendButton.enabled = false
        
        /*
        let chatBubbleData1 = ChatBubbleData(text: "Hey !!!!have a look on that....", image:UIImage(named: "chatImage1.jpg"), date: NSDate(), type: .Mine)
        addChatBubble(chatBubbleData1)
        
        let chatBubbleData2 = ChatBubbleData(text: "Nice.... what about this one", image:UIImage(named: "chatImage3.jpg"), date: NSDate(), type: .Opponent)
        addChatBubble(chatBubbleData2)
        
        let chatBubbleData3 = ChatBubbleData(text: "Great Bro....!!!", image:nil, date: NSDate(), type: .Mine)
        addChatBubble(chatBubbleData3)
        */
        self.messageCointainerScroll.contentSize = CGSizeMake(CGRectGetWidth(messageCointainerScroll.frame), lastChatBubbleY + internalPadding)
        self.addKeyboardNotifications()
        
        /*
        
        */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil)
        
    }
    
    // MARK:- Notification
    func keyboardWillShow(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            let duration:NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            self.BottomComposeViewLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            UIView.animateWithDuration(duration,
                delay: NSTimeInterval(0),
                options: animationCurve,
                animations: { self.view.layoutIfNeeded() },
                completion: nil)
        }
        
        /*
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()

        UIView.animateWithDuration(1.0, animations: { () -> Void in
            //self.buttomLayoutConstraint = keyboardFrame.size.height
            self.buttomLayoutConstraint.constant = keyboardFrame.size.height

            }) { (completed: Bool) -> Void in
                    self.moveToLastMessage()
        }
*/
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let duration:NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            self.BottomComposeViewLayoutConstraint?.constant = 0.0
            UIView.animateWithDuration(duration,
                delay: NSTimeInterval(0),
                options: animationCurve,
                animations: { self.view.layoutIfNeeded() },
                completion: nil)
        }
/*
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.buttomLayoutConstraint.constant = 0.0
            }) { (completed: Bool) -> Void in
                self.moveToLastMessage()
        }
*/
    }
    
    @IBAction func sendButtonClicked(sender: AnyObject) {
        self.addRandomTypeChatBubble()
        textField.resignFirstResponder()
    }
    
    @IBAction func cameraButtonClicked(sender: AnyObject) {
        self.presentViewController(imagePicker, animated: true, completion: nil)//4
    }
    
    
    func addRandomTypeChatBubble() {
        
        let textToSend = textField.text
        if textToSend != "" {
            chatterBoxClient.stopAdvertizing()
            chatterBoxClient.myMessage(textToSend!)
            self.chatterBoxClient.startAdvertizing()
            isSending = true
            self.textField.resignFirstResponder()
            
        } else {
            self.textField.resignFirstResponder()
        }
    }
    func loadList(notification: NSNotification){
       let bubbleData = ChatBubbleData(text: chatterBoxClient.message, image: selectedImage, date: NSDate(), type: getChatDataType())
        addChatBubble(bubbleData)

    }
    func addChatBubble(data: ChatBubbleData) {
        
        let padding:CGFloat = lastMessageType == data.type ? internalPadding/3.0 :  internalPadding
        let chatBubble = ChatBubble(data: data, startY:lastChatBubbleY + padding)
        self.messageCointainerScroll.addSubview(chatBubble)
        
        let bounds = chatBubble.bounds

        if data.type.hashValue == 0 {
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 10, options: [], animations: {
            chatBubble.bounds = CGRect(x: bounds.origin.x - 10, y: bounds.origin.y, width: bounds.size.width , height: bounds.size.height)
            
            }, completion: nil)
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 10, options: [], animations: {
            chatBubble.bounds = CGRect(x: bounds.origin.x + 10, y: bounds.origin.y, width: bounds.size.width , height: bounds.size.height)
            
            }, completion: nil)
        } else {
            UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 10, options: [], animations: {
                chatBubble.bounds = CGRect(x: bounds.origin.x + 10, y: bounds.origin.y, width: bounds.size.width , height: bounds.size.height)
                
                }, completion: nil)
            UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 10, options: [], animations: {
                chatBubble.bounds = CGRect(x: bounds.origin.x - 10, y: bounds.origin.y, width: bounds.size.width , height: bounds.size.height)
                
                }, completion: nil)
        }
       lastChatBubbleY = CGRectGetMaxY(chatBubble.frame)
        
        
        self.messageCointainerScroll.contentSize = CGSizeMake(CGRectGetWidth(messageCointainerScroll.frame), lastChatBubbleY + internalPadding)
        self.moveToLastMessage()
        lastMessageType = data.type
        textField.text = ""
        sendButton.enabled = false
    }
    
    func moveToLastMessage() {

        if messageCointainerScroll.contentSize.height > CGRectGetHeight(messageCointainerScroll.frame) {
            let contentOffSet = CGPointMake(0.0, messageCointainerScroll.contentSize.height - CGRectGetHeight(messageCointainerScroll.frame))
            self.messageCointainerScroll.setContentOffset(contentOffSet, animated: true)
        }
    }
    func getChatDataType() -> BubbleDataType {

        if incomingMessageID == MyGlobalPeerID{
            return BubbleDataType(rawValue: 0)!
        }else{
            return BubbleDataType(rawValue: 1)!
        }

        //return BubbleDataType(rawValue: Int(arc4random() % 2))!
    }
}


// MARK: TEXT FILED DELEGATE METHODS

extension ViewController{
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Send button clicked
        textField.resignFirstResponder()
        self.addRandomTypeChatBubble()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var text: String
        
        if string.characters.count > 0 {
            text = String(format:"%@%@",textField.text!, string);
        } else {
            var string = textField.text! as NSString
            text = string.substringToIndex(string.length - 1) as String
        }
        if text.characters.count > 0 {
            sendButton.enabled = true
        } else {
            sendButton.enabled = false
        }
        return true
    }
}

extension ViewController{
    //MARK: Delegates
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage //2
        let bubbleData = ChatBubbleData(text: textField.text, image: chosenImage, date: NSDate(), type: getChatDataType())
        addChatBubble(bubbleData)
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
}


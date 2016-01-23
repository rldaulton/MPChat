//
//  MultiPeerConnectivityManager.swift
//  Chatter
//
//  Created by Ryan Daulton 
//

import Foundation
import MultipeerConnectivity
import CoreData

protocol MultiPeerConnectivityManagerDelegate {
    func addMessage(id: String, message: String, name: String?)
    func removeMessage(id: String)
}

var MyGlobalPeerID = String!()
var incomingMessageID = String!()

@objc class MultiPeerConnectivityManager: NSObject {
    
    // MARK: Properties
    var delegate: MultiPeerConnectivityManagerDelegate?
    var peerID: MCPeerID?
    var session: MCSession?
    var browser: MCBrowserViewController?
    let serviceType = "oba-chatterbox"
    var broadcaster: MCNearbyServiceAdvertiser?
    var serviceBrowser: MCNearbyServiceBrowser?
    var messages = [String:MCPeerID]()
    var message = ""
    //var blockUsers = [String]()
    
    var messagesTable = [String]()
    var managedContext_MPCMangr: NSManagedObjectContext?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var reloadable: Bool!
    
    // MARK: Methods
    override init() {
        super.init()
        //    peerID = MCPeerID(displayName: "\(NSDate().timeIntervalSince1970)")
        peerID = MCPeerID(displayName: UIDevice.currentDevice().identifierForVendor!.UUIDString)
        MyGlobalPeerID = peerID!.displayName

        session = MCSession(peer: peerID!)
        session!.delegate = self
        
    }
    
    class func sharedInstance() -> MultiPeerConnectivityManager {
        return MultiPeerConnectivityManagerSingletonGlobal
    }
    
    func myMessage(message: String) {
        if message != "" {
            self.message = message
            //      peerID = MCPeerID(displayName: "\(NSDate().timeIntervalSince1970)")
            peerID = MCPeerID(displayName: UIDevice.currentDevice().identifierForVendor!.UUIDString)
            session = MCSession(peer: peerID!)
            
            
        }
    }
    
    func startAdvertizing() {
        let discoveryDictionary = ["date": "\(NSDate().timeIntervalSince1970)", "message": message, "name": ""];
        broadcaster = MCNearbyServiceAdvertiser(peer: peerID!, discoveryInfo: discoveryDictionary, serviceType: serviceType)
        broadcaster!.delegate = self
        broadcaster!.startAdvertisingPeer()
        print("Now Advertizing: \(broadcaster!.serviceType) with message [\(message)]")
    }
    
    func stopAdvertizing() {
        broadcaster!.stopAdvertisingPeer()
        //    println("Stopped Advertizing: \(broadcaster!.serviceType)")
        broadcaster = nil
    }
    
    func startBrowsing() {
        serviceBrowser = MCNearbyServiceBrowser(peer: peerID!, serviceType: serviceType)
        serviceBrowser!.delegate = self
        serviceBrowser!.startBrowsingForPeers()
        print("Now Browsing: \(serviceBrowser!.serviceType)")
    }
    
    func stopBrowsing() {
        serviceBrowser!.stopBrowsingForPeers()
        print("Stopped Browsing: \(serviceBrowser!.serviceType)")
        serviceBrowser = nil
    }
    
}

let MultiPeerConnectivityManagerSingletonGlobal = MultiPeerConnectivityManager()

// MARK: - Extensions
// MARK:

// MARK: MCNearbyServiceAdvertizer Delegate
extension MultiPeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: ((Bool, MCSession) -> Void)) {
        // refuse all connections, we don't need them
        //invitationHandler(false,session:nil)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("Did not start advertizing: \(error)")
    }
}

// MARK: MCSession Delegate
extension MultiPeerConnectivityManager: MCSessionDelegate {
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        // We don't receive data
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        // We don't accept resources
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        // We don't accept resources
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // We don't accept streams
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        // We don't accept connections
    }
    
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: ((Bool) -> Void)) {
        // We don't accept connections
    }
}

// MARK: MCNearbyServiceBrowser Delegate
extension MultiPeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        messages.updateValue(peerID, forKey: info!["date"] as String!)
        print("Peer Found")
        
        message = (info!["message"] as String!)
        incomingMessageID = peerID.displayName
        
        delegate?.addMessage((info!["date"] as String!), message: (info!["message"] as String!), name: info!["name"] as String!)
        print("Discovered:\npeerID: \(peerID)\ninfo: \(info) | Sent Message: '\(message)'")
       
        print("LAST SENDER ID: \(peerID.displayName)")

        
        ///If message is NOT blank, save to CoreData and Append to Messages
        
        if (info!["message"] as String!) != ""{
                        
            managedContext_MPCMangr = self.appDelegate.managedObjectContext!
            
            let entity = NSEntityDescription.entityForName("Feed", inManagedObjectContext: managedContext_MPCMangr!)
            let MsgToSave = Feed(entity: entity!, insertIntoManagedObjectContext: managedContext_MPCMangr!)
            MsgToSave.messages = (info!["message"] as String!)
            do {
                try managedContext_MPCMangr?.save()
            } catch _ {
            }
            messagesTable.append((info!["message"] as String!))
            print(messagesTable)
            
            NSNotificationCenter.defaultCenter().postNotificationName("load", object: nil)
        }
        
        
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Gone: \(peerID.description)")
        let messageKeys = messages.keys
        for key in messageKeys {
            if messages[key] == peerID {
                delegate?.removeMessage(key)
                return
            }
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("Did not start browsing: \(error)")
    }
}

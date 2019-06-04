//
//  MessageController.swift
//  CKBulletinBoard
//
//  Created by Will morris on 6/3/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import Foundation
import CloudKit

class MessageController {
    //Singleton
    static let shared = MessageController()
    //SoT
    var messages: [Message] = []
    // database
    let privateDB = CKContainer.default().privateCloudDatabase
    //CRUD
    
    //Create
    func createMessage(text: String, timestamp: Date, completion: @escaping (Bool) -> Void) {
        let message = Message(text: text, timestamp: timestamp)
        self.saveMessage(message: message, completion: completion)
    }
    //Remove / Delete
    func removeMessage(message: Message, completion: @escaping (Bool) -> ()) {
        // remove locally
        guard let index = MessageController.shared.messages.firstIndex(of: message) else { return }
        MessageController.shared.messages.remove(at: index)
        // remove cloud
        privateDB.delete(withRecordID: message.ckRecordID) { (_, error) in
            if let error = error {
                print("... There was an error in \(#function) : \(error) : \(error.localizedDescription)")
                completion(false)
                return
            } else {
                completion(true)
            }
        }
    }
    //Save
    func saveMessage(message: Message, completion: @escaping (Bool) -> ()) {
        let messageRecord = CKRecord(message: message)
        privateDB.save(messageRecord) { (record, error) in
            if let error = error {
                print("... There was an error in \(#function) : \(error) : \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let record = record, let message = Message(ckRecord: record) else { completion(false); return }
            self.messages.append(message)
            completion(true)
        }
    }
    //Load
    func fetchMessages(completion: @escaping (Bool) -> ()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Constants.recordKey, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("... There was an error in \(#function) : \(error) : \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let records = records else { completion(false); return }
            let messages = records.compactMap({Message(ckRecord: $0)})
            self.messages = messages
            completion(true)
        }
    }
    
    func subscribeToNotifications(completion: @escaping (Error?) -> Void) {
        
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(recordType: Constants.recordKey, predicate: predicate, options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New Post! Would you like to look?"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        
        subscription.notificationInfo = notificationInfo
        
        privateDB.save(subscription) { (_, error) in
            if let error = error {
                print("Subscription did not save: \(error.localizedDescription)")
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    func requestDiscoverabilityAuth(completion: @escaping (CKContainer_Application_PermissionStatus, Error?) -> Void) {
        CKContainer.default().status(forApplicationPermission: .userDiscoverability) { (status, error) in
            guard status != .granted else { completion(.granted, error); return }
            
            CKContainer.default().requestApplicationPermission(.userDiscoverability, completionHandler: completion)
        }
    }
    
    func fetchAllDiscoverableUsers(completion: @escaping ([CKUserIdentity], Error?) -> Void) {
        let discoverIdentities = CKDiscoverAllUserIdentitiesOperation()
        
        var discoverdIds: [CKUserIdentity] = []
        
        discoverIdentities.userIdentityDiscoveredBlock = { identity in
            discoverdIds.append(identity)
        }
        
        discoverIdentities.discoverAllUserIdentitiesCompletionBlock = { error in
            completion(discoverdIds, error)
        }
        
        CKContainer.default().add(discoverIdentities)
    }
    
    func fetchUserIdentityWith(email: String, completion: @escaping (CKUserIdentity?, Error?) -> Void) {
        CKContainer.default().discoverUserIdentity(withEmailAddress: email, completionHandler: completion)
    }
}

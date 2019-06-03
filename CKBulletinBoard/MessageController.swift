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
    func createMessage(text: String, timestamp: Date) {
        let message = Message(text: text, timestamp: timestamp)
        self.saveMessage(message: message) { (_) in
            
        }
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
}

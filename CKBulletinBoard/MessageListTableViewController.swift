//
//  MessageListTableViewController.swift
//  CKBulletinBoard
//
//  Created by Will morris on 6/3/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import UIKit

class MessageListTableViewController: UITableViewController {

    @IBOutlet weak var messageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MessageController.shared.fetchMessages { (success) in
            if success {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: AppDelegate.messageNotification, object: nil)
    }
    
    @objc func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func postButtonTapped(_ sender: Any) {
        guard let messageText = messageTextField.text else { return }
        MessageController.shared.createMessage(text: messageText, timestamp: Date()) { (success) in
            if success {
                DispatchQueue.main.async {
                    self.messageTextField.text = ""
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MessageController.shared.messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)

        let message = MessageController.shared.messages[indexPath.row]
        cell.textLabel?.text = message.text
        cell.detailTextLabel?.text = "\(message.timestamp)"
        
        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let message = MessageController.shared.messages[indexPath.row]
            MessageController.shared.removeMessage(message: message) { (success) in
                if success {
                    DispatchQueue.main.async {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            }
        }
    }
}

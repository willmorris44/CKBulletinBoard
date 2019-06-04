//
//  AppDelegate.swift
//  CKBulletinBoard
//
//  Created by Will morris on 6/3/19.
//  Copyright © 2019 devmtn. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let messageNotification = Notification.Name("MessageNotification")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (userResponse, error) in
            if let error = error {
                print("There was an issue requesting user notification permissions: \(error.localizedDescription)")
                return
            }
            
            if userResponse {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        MessageController.shared.requestDiscoverabilityAuth { (permission, error) in
            if let error = error {
                print("Error with user discoverability request: \(error.localizedDescription)")
            }
            
            print(permission)
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MessageController.shared.subscribeToNotifications { (error) in
            if let error = error {
                print("Error subscribing: \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        MessageController.shared.fetchMessages { (success) in
            if success {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: AppDelegate.messageNotification, object: self)
                }
            }
        }
    }
}


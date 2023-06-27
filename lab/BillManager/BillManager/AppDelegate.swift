//
//  AppDelegate.swift
//  BillManager
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let remindAction = UNNotificationAction(identifier: "remind", title: "Remind me in an Hour")
        let paidAction = UNNotificationAction(identifier: "markPaid", title: "Mark Bill as Paid", options: .authenticationRequired)
        
        let runNotificationCategory = UNNotificationCategory(identifier: "RunNofitication", actions: [remindAction, paidAction], intentIdentifiers: [])
        
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([runNotificationCategory])
        center.delegate = self
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationID = response.notification.request.identifier
        let database = Database()
        guard var bill = database.getBill(for: notificationID) else { return }
        
        if response.actionIdentifier == "markPaid" {
            bill.paidDate = Date()
            database.updateAndSave(bill)
        } else {
            let reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            bill.scheduleReminder(remindDate: reminderDate, completion: { _ in
                database.updateAndSave(bill)
            })
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let presentationOptions: UNNotificationPresentationOptions = [.list, .banner]
        completionHandler(presentationOptions)
    }
}


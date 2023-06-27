//
//  Bill+Extras.swift
//  BillManager
//

import UserNotifications

extension Bill {
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = dueDate.formatted(date: .numeric, time: .omitted)
        } else {
            dateString = ""
        }
        
        return dateString
    }
    
    mutating func removeReminders() {
        guard let notificationID else { return }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests (withIdentifiers: [notificationID])
        
        self.notificationID = nil
        self.remindDate = nil
    }
    
    mutating func scheduleReminder(remindDate: Date?, completion: @escaping (Bill) -> Void) {
        var updatedBill = self
        
        removeReminders()
        checkNotificationPermissions { granted in
            guard granted else {
                completion(updatedBill)
                return
            }
            
            guard
                let updatedAmount = updatedBill.amount,
                let updatedPayee = updatedBill.payee,
                let remindDate = updatedBill.remindDate
            else {
                print("Amount, Payee, or Remind Date not found.")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Bill Reminder"
            content.body = "$\(updatedAmount) to \(updatedPayee) due today!."
            content.categoryIdentifier = Bill.nofiticationCategoryID
            
            let triggerDateComponents = Calendar.current.dateComponents([.minute, .hour, .day, .month, .year], from: remindDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let newIdentifier = UUID().uuidString
            updatedBill.notificationID = newIdentifier
            
            let request = UNNotificationRequest(identifier: newIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { (error: Error?) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                        completion(updatedBill)
                    } else {
                        updatedBill.notificationID = newIdentifier
                        updatedBill.remindDate = remindDate
                        completion(updatedBill)
                    }
                }
            }
        }
    }

    func checkNotificationPermissions(completion: @escaping (Bool) -> ()) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
    
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert], completionHandler: { (granted, _) in
                   completion(granted)
                })
    
            case .denied, .provisional, .ephemeral:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
}

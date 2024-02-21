//
//  AppDelegate.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/2/7.
//

import UIKit
import Foundation
import UserNotifications
import NotificationBannerSwift

class iLoveTranscodeAppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, error in
            if success {
                UNUserNotificationCenter.current().getNotificationSettings { setting in
                    if setting.authorizationStatus == .authorized {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        return true
    }
    
}

extension iLoveTranscodeAppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print(response)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.threadIdentifier == "ConnectionEstablishedNotification" {
            completionHandler([])
            return
        } else if notification.request.content.threadIdentifier == "EndOfRenderNotification" ||
                    notification.request.content.threadIdentifier == "ServerQuitNotification"
        {
            completionHandler([.list, .banner, .sound])
        }
        completionHandler([.list, .banner, .sound])
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        guard token.count > 0 else { return }
        ParametersInMemory.shared.pushNotificationToken = token
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
    }
}

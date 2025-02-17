//
//  AppDelegate.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/18/25.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var userNotificationCenter = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOption: [UIApplication.LaunchOptionsKey: Any]?)
    -> Bool {
        // 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 백그라운드 작업 설정
           application.registerForRemoteNotifications()
        
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

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 포그라운드 상태일 때 알림 받기
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification:
                                UNNotification, withCompletionHandler completionHandler: @escaping
                                (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .badge, .sound])
    }
    
    // 알림을 탭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response:
                                UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

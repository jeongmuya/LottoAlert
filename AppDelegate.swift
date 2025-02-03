import UserNotifications
import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 알림 카테고리 설정
        let notificationCategory = UNNotificationCategory(
            identifier: "LOTTO_STORE_NEARBY",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([notificationCategory])
        
        // 백그라운드 작업 등록
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.yourapp.refresh",
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.yourapp.location-update",
            using: nil
        ) { task in
            self.handleLocationUpdate(task: task as! BGProcessingTask)
        }
        
        return true
    }
    
    // 앱이 foreground 상태일 때도 알림을 표시하기 위한 델리게이트 메서드
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
        print("✅ 알림 표시됨: \(notification.request.content.title)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        print("✅ 알림 응답 받음: \(response.notification.request.content.title)")
        completionHandler()
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // 백그라운드 데이터 갱신 처리
        scheduleNextAppRefresh()
    }
    
    private func handleLocationUpdate(task: BGProcessingTask) {
        // 백그라운드 위치 업데이트 처리
        scheduleNextLocationUpdate()
    }
    
    private func scheduleNextAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15분 후
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func scheduleNextLocationUpdate() {
        let request = BGProcessingTaskRequest(identifier: "com.yourapp.location-update")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule location update: \(error)")
        }
    }
} 
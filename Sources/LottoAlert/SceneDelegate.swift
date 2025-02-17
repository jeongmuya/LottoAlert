    //
    //  SceneDelegate.swift
    //  LottoAlert
    //
    //  Created by YangJeongMu on 1/18/25.
    //

    import UIKit

    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        
        var window: UIWindow?
        
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let windowScene = (scene as? UIWindowScene) else { return }
            
            window = UIWindow(windowScene: windowScene)
            
            // 런치스크린 전환 애니메이션 추가
            let launchScreenVC = LaunchScreenViewController()
            launchScreenVC.completionHandler = { [weak self] in
                // 크로스 디졸브 애니메이션 추가
                let tabBarController = TabBarController()
                UIView.transition(with: self?.window ?? UIWindow(),
                                  duration: 0.3,
                                  options: .transitionCrossDissolve) {
                    self?.window?.rootViewController = tabBarController
                } completion: { _ in
                    // : 딥링크 처리 위치 이동
                    self?.handleConnectionOptions(connectionOptions)
                }
            }
            
            window?.rootViewController = launchScreenVC
            window?.makeKeyAndVisible()
            
        }
        func sceneDidDisconnect(_ scene: UIScene) {
            // 리소스 정리 작업
            saveApplicationState()
        }
        
        func sceneDidBecomeActive(_ scene: UIScene) {
            // 뱃지 초기화
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            // 필요한 경우 위치 업데이트 재시작
            // LocationManager.shared.startUpdatingLocation()
        }
        
        func sceneWillResignActive(_ scene: UIScene) {
            // 필요한 경우 진행 중인 작업 저장
            saveApplicationState()
        }
        
        func sceneWillEnterForeground(_ scene: UIScene) {
            // 필요한 경우 데이터 새로고침
            // refreshData()
        }
        
        // MARK: - 수정 필요 4: 백그라운드 작업 스케줄러 설정 추가
        func sceneDidEnterBackground(_ scene: UIScene) {
            saveApplicationState()
            scheduleAppRefresh()
            scheduleLocationUpdates()
        }
        
        // MARK: - 수정 필요 5: 백그라운드 작업 스케줄러 메서드 추가
        
        private func scheduleAppRefresh() {
            // 백그라운드 새로고침 작업 스케줄링
        }
        
        private func scheduleLocationUpdates() {
            // 백그라운드 위치 업데이트 작업 스케줄링
        }
    
        
        // MARK: - Helper Methods
        
        private func handleConnectionOptions(_ connectionOptions: UIScene.ConnectionOptions) {
            // 알림을 통한 실행 처리
            if let notification = connectionOptions.notificationResponse {
                let userInfo = notification.notification.request.content.userInfo
                // 알림 데이터 처리
                handleNotification(userInfo)
            }
        }
        
        private func saveApplicationState() {
            // 앱 상태 저장이 필요한 경우 구현
        }
        
        private func handleNotification(_ userInfo: [AnyHashable: Any]) {
            // 알림 처리 로직
            // 예: 특정 로또 판매점 위치로 이동
        }
    }


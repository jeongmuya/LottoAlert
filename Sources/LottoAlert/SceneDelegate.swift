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
            
            // 윈도우 설정
            window = UIWindow(windowScene: windowScene)
            
            // 런치스크린 뷰컨트롤러 설정
            let launchScreenVC = LaunchScreenViewController()
            
            // 애니메이션 완료 후 실행될 코드
            launchScreenVC.completionHandler = { [weak self] in
                // 탭바 컨트롤러로 전환
                let tabBarController = TabBarController()
                self?.window?.rootViewController = tabBarController
                
                // 딥링크 처리
                self?.handleConnectionOptions(connectionOptions)
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
        
        func sceneDidEnterBackground(_ scene: UIScene) {
            // 백그라운드 진입 시 필요한 작업 수행
            saveApplicationState()
            
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


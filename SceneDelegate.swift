import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // 위치 모니터링 시작
        setupLocationMonitoring()
        
        let tabBarController = TabBarController()
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        // 알림을 통해 앱이 실행된 경우 처리
        if let notificationResponse = connectionOptions.notificationResponse {
            let userInfo = notificationResponse.notification.request.content.userInfo
            navigateToNumberRecommend(with: userInfo)
        }
    }

    func navigateToNumberRecommend(with userInfo: [AnyHashable: Any]) {
        print("🔄 화면 전환 시도 - userInfo: \(userInfo)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let tabBarController = self.window?.rootViewController as? TabBarController else {
                print("❌ TabBarController 찾기 실패")
                return
            }
            
            // 번호 추천 화면으로 전환
            tabBarController.selectedIndex = 1
            
            // 알림에서 전달된 번호 정보 추출 및 표시
            if let numbersString = userInfo["recommendedNumbers"] as? String,
               let navController = tabBarController.selectedViewController as? UINavigationController,
               let numberVC = navController.viewControllers.first as? NumberRecommendViewController {
                print("✅ 번호 추천 화면으로 이동 성공: \(numbersString)")
                numberVC.displayNotificationNumbers(numbersString)
            } else {
                print("❌ 번호 추천 화면 설정 실패")
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene, willBeRemoved: Bool) {
        // Called when scene is being removed from a session.
        // If any sessions are being created, this will be called shortly after scene is being created.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene when it is being created.
        // The scene may re-connect later, as its session is not necessarily being created anew (see `application:configurationForConnecting` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene is being presented.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was being inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene is being being removed from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called when the scene is being being moved from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called when the scene is being being moved from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene when it is being created.
        // The scene may be being created when being re-connected.
    }

    private func setupLocationMonitoring() {
        // 위치 권한 요청 및 모니터링 시작
        LocationManager.shared.requestLocationAuthorization()
        LocationManager.shared.startUpdatingLocation()
    }
} 
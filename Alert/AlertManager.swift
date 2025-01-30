//
//  Untitled.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/18/25.
//

import UIKit
import UserNotifications

class AlertManager {
    static let shared = AlertManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private var lastNotificationTime: Date?
    private let minimumNotificationInterval: TimeInterval = 5 // 알림 간 최소 간격 (초)
    private var notificationCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .notificationCountDidChange,
                    object: nil,
                    userInfo: ["count": self.notificationCount]
                )
            }
        }
    }
    
    private init() {}
    
    // MARK: - Permission
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("✅ 알림 권한이 허용되었습니다.")
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else if let error = error {
                        print("❌ 알림 권한 요청 실패: \(error.localizedDescription)")
                    }
                    completion(granted)
                }
            case .denied:
                print("⚠️ 알림 권한이 거부되었습니다.")
                completion(false)
            case .authorized:
                print("✅ 이미 알림 권한이 허용되어 있습니다.")
                completion(true)
            default:
                completion(false)
            }
        }
    }
    
    // MARK: - Store Notifications
    func sendStoreNotification(store: LottoStore, distance: Int, numbers: [Int]) {
        // 마지막 알림과의 시간 간격 체크
        if let lastTime = lastNotificationTime,
           Date().timeIntervalSince(lastTime) < minimumNotificationInterval {
            print("⏱ 알림 간격이 너무 짧습니다. 건너뜁니다.")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🎱 로또 번호 추천"
        content.body = """
            \(store.name) 근처입니다! (약 \(distance)m)
            주소: \(store.address)
            추천 번호: \(numbers.map { String(format: "%02d", $0) }.joined(separator: ", "))
            """
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: notificationCount + 1)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 알림 전송 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 알림 전송 성공: \(store.name) (\(distance)m)")
                    self?.notificationCount += 1
                    self?.lastNotificationTime = Date()
                    
                    // 추천 번호 저장 로직 수정
                    let recommendation = LottoRecommendation(
                        numbers: numbers,
                        storeName: store.name
                    )
                    
                    // UserDefaults에 직접 저장
                    if let encoded = try? JSONEncoder().encode([recommendation]) {
                        var existingRecommendations: [LottoRecommendation] = []
                        
                        // 기존 데이터 로드
                        if let data = UserDefaults.standard.data(forKey: "lottoRecommendations"),
                           let decoded = try? JSONDecoder().decode([LottoRecommendation].self, from: data) {
                            existingRecommendations = decoded
                        }
                        
                        // 새로운 추천 번호를 맨 앞에 추가
                        existingRecommendations.insert(recommendation, at: 0)
                        
                        // 최대 50개까지만 유지
                        if existingRecommendations.count > 50 {
                            existingRecommendations = Array(existingRecommendations.prefix(50))
                        }
                        
                        // 다시 인코딩하여 저장
                        if let updatedData = try? JSONEncoder().encode(existingRecommendations) {
                            UserDefaults.standard.set(updatedData, forKey: "lottoRecommendations")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Alerts
    func showPermissionAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "알림 권한 필요",
            message: "로또 번호 추천을 받기 위해서는 알림 권한이 필요합니다. 설정에서 알림을 허용해주세요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        viewController.present(alert, animated: true)
    }
    
    func showLottoNumbersAlert(on viewController: UIViewController, numbers: [Int]) {
        let alert = UIAlertController(
            title: "🎱 오늘의 추천 번호",
            message: """
                행운의 번호:
                \(numbers.map { String(format: "%02d", $0) }.joined(separator: " - "))
                """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "번호 복사", style: .default) { _ in
            let numbersText = numbers.map { String(format: "%02d", $0) }.joined(separator: " ")
            UIPasteboard.general.string = numbersText
            self.showToast(message: "번호가 복사되었습니다", on: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "다시 생성", style: .default) { [weak viewController] _ in
            guard let vc = viewController else { return }
            self.showLottoNumbersAlert(on: vc, numbers: self.generateLottoNumbers())
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        viewController.present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func generateLottoNumbers() -> [Int] {
        var numbers = Set<Int>()
        while numbers.count < 6 {
            numbers.insert(Int.random(in: 1...45))
        }
        return Array(numbers).sorted()
    }
    
    private func showToast(message: String, on viewController: UIViewController) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        let toastContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewController.view.frame.size.width, height: 40))
        toastContainer.backgroundColor = .clear
        toastContainer.addSubview(toastLabel)
        viewController.view.addSubview(toastContainer)
        
        toastLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(35)
        }
        
        UIView.animate(withDuration: 2.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastContainer.removeFromSuperview()
        })
    }
    
    // 새로운 메서드 추가
    func clearNotificationCount() {
        notificationCount = 0
    }
}

// Notification.Name 확장
extension Notification.Name {
    static let notificationCountDidChange = Notification.Name("notificationCountDidChange")
}


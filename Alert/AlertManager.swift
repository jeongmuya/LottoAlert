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
    private var lastNotificationTimes: [String: Date] = [:] // 판매점별 마지막 알림 시간
    private let minimumNotificationInterval: TimeInterval = 3600 // 1시간
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
    
    private init() {
        requestNotificationPermission { granted in
            if granted {
                print("✅ 초기 알림 권한 설정 완료")
            } else {
                print("⚠️ 초기 알림 권한 거부됨")
            }
        }
    }
    
    // MARK: - Permission
    func requestNotificationPermission(completionHandler: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            completionHandler(granted)
        }
    }
    
    // MARK: - Store Notifications
    func sendLottoStoreNotification(for store: LottoStore) {
        // 마지막 알림 시간 확인
        if let lastTime = lastNotificationTimes[store.id ?? ""],
           Date().timeIntervalSince(lastTime) < minimumNotificationInterval {
            print("⏱ 알림 간격이 너무 짧습니다: \(store.name)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "근처에 로또 판매점이 있습니다!"
        content.body = "\(store.name)이(가) 근처에 있습니다. 행운의 번호를 구매해보세요!"
        content.sound = .default
        
        // 즉시 알림 전송
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 알림 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 알림 전송 성공: \(store.name)")
                // 마지막 알림 시간 업데이트
                self.lastNotificationTimes[store.id ?? ""] = Date()
            }
        }
    }
    
    // MARK: - Custom Alerts
    func showPermissionAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "알림 권한 필요",
            message: "로또 판매점 근처 알림을 받기 위해서는 알림 권한이 필요합니다.",
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


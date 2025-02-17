//
//  AlertManagers.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/12/25.
//

import Foundation
import UserNotifications
import CoreLocation
import UIKit

class AlertManager: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    static let shared = AlertManager()
    private let locationManager = CLLocationManager()
    private let notificationDistance: Double = 300 // 300미터 반경
    private var stores: [LottoStore] = [] // 로또 판매점 데이터 저장용
    private var lastNotifiedStores: Set<String> = [] // 중복 알림 방지용
    
    private override init() {
        super.init()
        setupLocationManager()
        setupNotifications()
        loadStoreData()
    }
    
    // MARK: - Setup Methods
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        // 백그라운드 위치 권한 요청
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    private func loadStoreData() {
        if let path = Bundle.main.path(forResource: "LottoStores", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                stores = try decoder.decode([LottoStore].self, from: data)
                print("로또 판매점 데이터 로드 완료: \(stores.count)개")
            } catch {
                print("로또 판매점 데이터 로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Location Manager Delegate Methods
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("위치 권한 항상 허용")
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startUpdatingLocation()
        case .authorizedWhenInUse:
            print("위치 권한 사용 중일 때만 허용")
            requestAlwaysAuthorization()
        default:
            print("위치 권한 없음")
            showLocationPermissionAlert()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        
        // 백그라운드 상태에서는 배터리 절약을 위해 정확도 조정
        if UIApplication.shared.applicationState == .background {
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
        
        print("📍 위치 업데이트: lat: \(currentLocation.coordinate.latitude), lon: \(currentLocation.coordinate.longitude), 시간: \(Date())")
        
        checkAndNotifyNearbyStores(at: currentLocation)
    }
    
    // MARK: - Notification Methods
    
    private func checkAndNotifyNearbyStores(at location: CLLocation) {
        let nearbyStores = stores.filter { store in
            let storeLocation = CLLocation(
                latitude: store.latitude,
                longitude: store.longitude
            )
            return location.distance(from: storeLocation) <= notificationDistance
        }
        
        for store in nearbyStores {
            if !lastNotifiedStores.contains(store.name) {
                sendNotification(for: store)
                lastNotifiedStores.insert(store.name)
            }
        }
        
        lastNotifiedStores = Set(nearbyStores.map { $0.name })
    }
    
    private func sendNotification(for store: LottoStore) {
        let content = UNMutableNotificationContent()
        content.title = "근처에 로또 판매점이 있습니다!"
        content.body = "판매점: \(store.name)"
        content.sound = .default
        content.userInfo = ["storeName": store.name]
        
        let request = UNNotificationRequest(
            identifier: "storeNotification_\(store.name)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 설정 실패: \(error.localizedDescription)")
            } else {
                print("근처 판매점 알림 전송 완료: \(store.name)")
            }
        }
    }
    
    // MARK: - Permission Handling
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("알림 권한이 허용되었습니다")
            } else {
                print("알림 권한이 거부되었습니다")
                self.showNotificationPermissionAlert()
            }
        }
    }
    
    private func requestAlwaysAuthorization() {
        let alert = UIAlertController(
            title: "백그라운드 위치 권한 필요",
            message: "로또 판매점 알림을 받으시려면 '항상 허용' 권한이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "로또 판매점 알림을 받으시려면 위치 권한이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: "알림 권한 필요",
            message: "로또 판매점 알림을 받으시려면 알림 권한이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

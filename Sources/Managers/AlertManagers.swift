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
        // 정확도를 낮추어 배터리 소모 감소
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        // 거리 필터를 증가시켜 업데이트 빈도 감소
        locationManager.distanceFilter = 200 // 200미터마다 업데이트
        locationManager.allowsBackgroundLocationUpdates = true
        // 자동 일시 중지 활성화
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = true
        
        locationManager.requestAlwaysAuthorization()
        // significantLocationChanges 사용
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
    
    private var monitoredRegions: Set<String> = []

    private func setupRegionMonitoring(for store: LottoStore) {
        // 이미 모니터링 중인 region인지 확인
        if locationManager.monitoredRegions.count >= 20 {
            // 가장 오래된 region 제거
            if let oldestRegion = locationManager.monitoredRegions.first {
                locationManager.stopMonitoring(for: oldestRegion)
                monitoredRegions.remove(oldestRegion.identifier)
            }
        }
        
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude),
            radius: notificationDistance,
            identifier: store.name
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
        monitoredRegions.insert(store.name)
    }

    // Region Monitoring Delegate 메서드 추가
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let store = stores.first(where: { $0.name == region.identifier }) {
            sendNotification(for: store)
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        
        // 백그라운드에서는 더 효율적인 방식으로 동작
        if UIApplication.shared.applicationState == .background {
            // 주변 판매점에 대한 Region Monitoring 설정
            let nearbyStores = stores.filter { store in
                let storeLocation = CLLocation(
                    latitude: store.latitude,
                    longitude: store.longitude
                )
                return currentLocation.distance(from: storeLocation) <= 1000 // 1km 이내
            }
            
            // 가까운 판매점들에 대해서만 Region Monitoring 설정
            nearbyStores.forEach { setupRegionMonitoring(for: $0) }
            
            // 불필요한 위치 업데이트 중지
            locationManager.stopUpdatingLocation()
        } else {
            checkAndNotifyNearbyStores(at: currentLocation)
        }
    }

    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let currentLocation = locations.last else { return }
//        
//        // 백그라운드 상태에서는 배터리 절약을 위해 정확도 조정
//        if UIApplication.shared.applicationState == .background {
//            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
//        } else {
//            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
//        }
//        
//        print("📍 위치 업데이트: lat: \(currentLocation.coordinate.latitude), lon: \(currentLocation.coordinate.longitude), 시간: \(Date())")
//        
//        checkAndNotifyNearbyStores(at: currentLocation)
//    }
    
    
    // MARK: - Error Handling Methods

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Region monitoring failed: \(error.localizedDescription)")
        if let region = region {
            monitoredRegions.remove(region.identifier)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
        if (error as? CLError)?.code == .denied {
            manager.stopUpdatingLocation()
            showLocationPermissionAlert()
        }
    }

    // MARK: - Memory Management

    private func cleanupOldNotificationData() {
        let currentTime = Date()
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        
        for key in keys where key.hasPrefix("lastNotified_") {
            if let lastDate = UserDefaults.standard.object(forKey: key) as? Date,
               currentTime.timeIntervalSince(lastDate) > 86400 { // 24시간
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Optimization Methods

    func optimizeLocationUpdates(for state: UIApplication.State) {
        switch state {
        case .background:
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
            locationManager.distanceFilter = 200
            // Region Monitoring에 집중
            locationManager.stopUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        case .active:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 100
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    // MARK: - Region Monitoring Management

    private func updateRegionMonitoring(at location: CLLocation) {
        // 현재 모니터링 중인 regions 중 멀어진 것들 제거
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion else { continue }
            let regionCenter = CLLocation(
                latitude: circularRegion.center.latitude,
                longitude: circularRegion.center.longitude
            )
            
            if location.distance(from: regionCenter) > 2000 { // 2km 이상 멀어진 경우
                locationManager.stopMonitoring(for: region)
                monitoredRegions.remove(region.identifier)
            }
        }
        
        // 새로운 nearby stores 모니터링 설정
        let nearbyStores = stores.filter { store in
            let storeLocation = CLLocation(
                latitude: store.latitude,
                longitude: store.longitude
            )
            return location.distance(from: storeLocation) <= 1000 // 1km 이내
        }
        
        for store in nearbyStores {
            setupRegionMonitoring(for: store)
        }
    }

    
    private func updateLocationAccuracy() {
        if CLLocationManager.locationServicesEnabled() {
            switch UIApplication.shared.applicationState {
            case .background:
                if locationManager.monitoredRegions.isEmpty {
                    // 모니터링 중인 region이 없는 경우 significant location changes만 사용
                    locationManager.stopUpdatingLocation()
                    locationManager.startMonitoringSignificantLocationChanges()
                }
            case .active:
                // 앱이 활성화된 경우 정확한 위치 업데이트 사용
                locationManager.startUpdatingLocation()
            default:
                break
            }
        }
    }

    
    // MARK: - Notification Methods
    
    private func checkAndNotifyNearbyStores(at location: CLLocation) {
        // 마지막 알림 시간 확인
        let currentTime = Date()
        let minimumInterval: TimeInterval = 3600 // 1시간
        
        let nearbyStores = stores.filter { store in
            let storeLocation = CLLocation(
                latitude: store.latitude,
                longitude: store.longitude
            )
            return location.distance(from: storeLocation) <= notificationDistance
        }
        
        for store in nearbyStores {
            if let lastNotified = UserDefaults.standard.object(forKey: "lastNotified_\(store.name)") as? Date {
                if currentTime.timeIntervalSince(lastNotified) < minimumInterval {
                    continue
                }
            }
            
            sendNotification(for: store)
            UserDefaults.standard.set(currentTime, forKey: "lastNotified_\(store.name)")
        }
    }

    
//    private func checkAndNotifyNearbyStores(at location: CLLocation) {
//        let nearbyStores = stores.filter { store in
//            let storeLocation = CLLocation(
//                latitude: store.latitude,
//                longitude: store.longitude
//            )
//            return location.distance(from: storeLocation) <= notificationDistance
//        }
//        
//        for store in nearbyStores {
//            if !lastNotifiedStores.contains(store.name) {
//                sendNotification(for: store)
//                lastNotifiedStores.insert(store.name)
//            }
//        }
//        
//        lastNotifiedStores = Set(nearbyStores.map { $0.name })
//    }
    
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
            title: "위치 권한 안내",
            message: "로또 판매점 근처 알림을 받으시려면 '항상 허용' 권한이 필요합니다. 이 권한은 판매점 근처에서만 사용되며, 배터리 효율을 위해 최적화되어 있습니다.",
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

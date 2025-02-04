//
//  LocationManager.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/22/25.
//


import CoreLocation
import UserNotifications

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // 반경 설정을 1000m로 변경
    private let storeProximityRadius: Double = 1000  // 1km로 변경
    // 이미 알림을 보낸 판매점 추적
    private var notifiedStoreIds = Set<String>()
    
    var authorizationStatusHandler: ((CLAuthorizationStatus) -> Void)?
    var locationUpdateHandler: ((CLLocation) -> Void)?
    
    private override init() {
        super.init()
        setupLocationManager()
        requestNotificationAuthorization()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    private func requestNotificationAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if granted {
                print("✅ 알림 권한 승인됨")
                // 알림 설정 초기화
                self?.resetNotifications()
            } else if let error = error {
                print("❌ 알림 권한 요청 실패: \(error)")
            }
        }
    }
    
    func requestLocationAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        print("📍 현재 위치 업데이트: \(currentLocation.coordinate)")
        
        locationUpdateHandler?(currentLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusHandler?(status)
    }
    
    // 알림 초기화 (앱 재시작시 등에 사용)
    func resetNotifications() {
        notifiedStoreIds.removeAll()
    }
    
    // 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // 현재 위치 반환
    var currentLocation: CLLocation? {
        return locationManager.location
    }
}

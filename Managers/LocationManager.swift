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
        checkNearbyLottoStores(at: currentLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusHandler?(status)
    }
    
    // MARK: - Nearby Store Detection
    private func checkNearbyLottoStores(at location: CLLocation) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let stores = CoreDataManager.shared.fetchStores()
            
            for store in stores {
                guard let latitude = Double(store.latitude ?? ""),
                      let longitude = Double(store.longitude ?? ""),
                      let storeId = store.id else { continue }
                
                let storeLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distance = location.distance(from: storeLocation)
                
                if distance <= self.storeProximityRadius && !self.notifiedStoreIds.contains(storeId) {
                    DispatchQueue.main.async {
                        self.sendProximityNotification(for: store)
                        self.notifiedStoreIds.insert(storeId)
                        
                        // 12시간 후에 해당 판매점 알림 재설정
                        DispatchQueue.main.asyncAfter(deadline: .now() + 43200) {
                            self.notifiedStoreIds.remove(storeId)
                        }
                    }
                }
            }
        }
    }
    
    private func sendProximityNotification(for store: LottoStore) {
        let content = UNMutableNotificationContent()
        content.title = "1km 이내에 로또 판매점이 있습니다!"  // 메시지 수정
        content.body = "\(store.name)\n주소: \(store.address)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 알림 전송 실패: \(error)")
            } else {
                print("✅ 알림 전송 성공: \(store.name) - 거리: 1km 이내")
            }
        }
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

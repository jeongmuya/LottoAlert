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
    private(set) var currentLocation: CLLocation?
    private let monitoringRadius: CLLocationDistance = 1000 // 1km
    private var monitoredStores: [LottoStore] = []
    private let alertManager = AlertManager.shared
    
    var locationUpdateHandler: ((CLLocation) -> Void)?
    var authorizationStatusHandler: ((CLAuthorizationStatus) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true // 백그라운드 위치 업데이트 허용
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        // 이전 위치 정보 초기화
        currentLocation = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// 판매점 주변 지오펜스 설정
    func setupGeofencing(for store: LottoStore, radius: Double = 100) {
        guard let latString = store.latitude,
              let lngString = store.longitude,
              let latitude = Double(latString),
              let longitude = Double(lngString) else {
            print("⚠️ 지오펜싱 설정 실패: 좌표 정보 없음 - \(store.name)")
            return
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: String(store.number)  // store.number를 String으로 변환하여 사용
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        // 이미 모니터링 중인 지역이 20개 미만일 때만 추가
        if locationManager.monitoredRegions.count < 20 {
            locationManager.startMonitoring(for: region)
            monitoredStores.append(store)
        }
    }
    
    /// 지오펜스 모니터링 중지
    func stopGeofencing(for store: LottoStore) {
        let identifier = String(store.number)
        locationManager.monitoredRegions
            .filter { $0.identifier == identifier }
            .forEach { locationManager.stopMonitoring(for: $0) }
        
        monitoredStores.removeAll { String($0.number) == identifier }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        
        // 위치 업데이트 핸들러 호출
        locationUpdateHandler?(currentLocation!)
        
        // 위치를 받아온 후 업데이트 중지
        stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusHandler?(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let store = monitoredStores.first(where: { String($0.number) == region.identifier }) else { return }
        print("🎯 판매점 반경 진입: \(store.name)")
        
        // 알림 전송
        alertManager.sendLottoStoreNotification(for: store)
    }
    
    // MARK: - Private Methods
    
    private func sendLocalNotification(for store: LottoStore) {
        let content = UNMutableNotificationContent()
        content.title = "근처에 로또 판매점이 있습니다!"
        content.body = "\(store.name)이(가) 근처에 있습니다. 행운의 번호를 구매해보세요!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification Error: \(error.localizedDescription)")
            }
        }
    }
    
    // 위치 필터링 로직
    func filterStoresByLocation(_ stores: [LottoStore]) -> [LottoStore] {
        guard let currentLocation = self.currentLocation else { return [] }
        
        return stores.filter { store in
            guard let latitude = store.latitude,
                  let longitude = store.longitude,
                  let lat = Double(latitude),
                  let lng = Double(longitude) else {
                return false
            }
            
            let storeLocation = CLLocation(latitude: lat, longitude: lng)
            let distance = currentLocation.distance(from: storeLocation)
            return distance <= 3000 // 3km 반경 내 매장만 필터링
        }
    }
    
    // 위치 업데이트 메서드 추가
    func updateCurrentLocation(_ location: CLLocation) {
        currentLocation = location
    }
    
    // 판매점 모니터링 시작
    func startMonitoringStores(_ stores: [LottoStore]) {
        // 기존 모니터링 중인 지역 제거
        monitoredStores.forEach { store in
            let identifier = String(store.number)
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(
                    latitude: Double(store.latitude ?? "0") ?? 0,
                    longitude: Double(store.longitude ?? "0") ?? 0
                ),
                radius: monitoringRadius,
                identifier: identifier
            )
            locationManager.stopMonitoring(for: region)
        }
        
        // 새로운 판매점 모니터링 시작
        stores.forEach { store in
            // Optional String 안전하게 처리
            guard let latitude = store.latitude,
                  let longitude = store.longitude,
                  let latitudeDouble = Double(latitude),
                  let longitudeDouble = Double(longitude) else {
                print("⚠️ 판매점 좌표 변환 실패: \(store.name)")
                return
            }
            
            let identifier = String(store.number)
            let coordinate = CLLocationCoordinate2D(latitude: latitudeDouble, longitude: longitudeDouble)
            let region = CLCircularRegion(
                center: coordinate,
                radius: monitoringRadius,
                identifier: identifier
            )
            
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            locationManager.startMonitoring(for: region)
            print("🎯 판매점 모니터링 시작: \(store.name)")
        }
        
        monitoredStores = stores
    }
}

import CoreLocation
import UserNotifications

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private let storeProximityRadius: Double = 1000  // 1km
    private var monitoredRegions = Set<CLCircularRegion>()
    private var lastNotificationTimes: [String: Date] = [:]
    private let minimumNotificationInterval: TimeInterval = 3600 // 1시간
    private(set) var currentLocation: CLLocation?
    
    var authorizationStatusHandler: ((CLAuthorizationStatus) -> Void)?
    var locationUpdateHandler: ((CLLocation) -> Void)?
    
    private override init() {
        super.init()
        setupLocationManager()
        requestNotificationPermission()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 알림 권한 승인됨")
            } else if let error = error {
                print("❌ 알림 권한 요청 실패: \(error)")
            }
        }
    }
    
    func requestLocationAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startMonitoringStores(_ stores: [LottoStore]) {
        // 기존 모니터링 중지
        monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        monitoredRegions.removeAll()
        
        for store in stores {
            guard let latitude = Double(store.latitude ?? ""),
                  let longitude = Double(store.longitude ?? ""),
                  let storeId = store.id else { continue }
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = CLCircularRegion(
                center: coordinate,
                radius: storeProximityRadius,
                identifier: "\(storeId)|\(store.name)"
            )
            
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            locationManager.startMonitoring(for: region)
            monitoredRegions.insert(region)
        }
        
        print("✅ 총 \(monitoredRegions.count)개의 판매점 모니터링 시작")
    }
    
    // MARK: - Notifications
    private func sendStoreNotification(storeName: String) {
        // 마지막 알림 시간 확인
        if let lastTime = lastNotificationTimes[storeName],
           Date().timeIntervalSince(lastTime) < minimumNotificationInterval {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "근처에 로또 판매점이 있습니다!"
        content.body = "\(storeName)이(가) 근처에 있습니다. 행운의 번호를 구매해보세요!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 알림 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 알림 전송 성공: \(storeName)")
                self.lastNotificationTimes[storeName] = Date()
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        let components = circularRegion.identifier.split(separator: "|")
        guard components.count == 2 else { return }
        
        let storeName = String(components[1])
        sendStoreNotification(storeName: storeName)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationUpdateHandler?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusHandler?(status)
    }
}


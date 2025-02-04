//
//  Untitled.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/18/25.
//

import UIKit
import NMapsMap
import SnapKit
import CoreLocation
import UserNotifications

class MapViewController: UIViewController {
    
    // MARK: - Properties
    private let mapView = NMFMapView()
    private let locationManager = CLLocationManager()
    private let lottoAPIManager = LottoAPIManager.shared
    private var stores: [LottoStore] = []
    private var visibleMarkers: [String: NMFMarker] = [:]
    private lazy var markerManager = MarkerManager(mapView: mapView)
    private let geocodingService = GeocodingService()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let monitoringRadius: CLLocationDistance = 1000 // 1km 반경
    private var monitoredRegions: [CLCircularRegion] = []

    private let currentLocationButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "location"), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 25
        button.tintColor = .systemBlue
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.2
        return button
    }()
        
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //        setupUI()
        setupMapView()
        setupMarkerManager()
        setupLocationManager()
        setupActions()
        
        // 위치 권한 확인 및 위치 업데이트 시작
        checkLocationAuthorization()
        loadLottoStores()
        
        // 카메라 델리게이트 설정
//        mapView.addCameraDelegate(delegate: self)
    }
    
    // MARK: - Setup Methods
    private func setupMapView() {
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mapView.positionMode = .direction
        mapView.zoomLevel = 15
        mapView.minZoomLevel = 10
        mapView.maxZoomLevel = 20
        
        // 델리게이트 설정 수정
//        mapView.addCameraDelegate(delegate: self)  // delegate: 파라미터 명시
    }
    
    private func setupMarkerManager() {
        // 마커 터치 핸들러 설정 제거
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 50
        
        // 위치 권한 요청
        locationManager.requestAlwaysAuthorization()
        
        // 알림 권한 요청 - 클로저를 별도 함수로 분리
        requestNotificationAuthorization()
    }
    
    private func requestNotificationAuthorization() {
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(
            options: options,
            completionHandler: handleNotificationAuthorizationResponse
        )
    }
    
    private func handleNotificationAuthorizationResponse(granted: Bool, error: Error?) {
        if granted {
            print("✅ 알림 권한 허용됨")
        } else {
            print("❌ 알림 권한 거부됨: \(error?.localizedDescription ?? "unknown error")")
        }
    }
    
    private func setupActions() {
        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonTapped), for: .touchUpInside)
    }

    
//    private func requestNotificationPermission() {
//        // 클로저를 별도의 메서드로 분리
//        let completionHandler: (Bool) -> Void = { [weak self] granted in
//            guard let self = self else { return }
//            
//            if !granted {
//                DispatchQueue.main.async {
//                    self.alertManager.showPermissionAlert(on: self)
//                }
//            }
//        }
//        
//        // 명시적인 파라미터로 전달
//        alertManager.requestNotificationPermission(completionHandler: completionHandler)
//    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            print("✅ 위치 권한 승인됨")
        case .denied, .restricted:
            showLocationPermissionAlert()
            print("❌ 위치 권한 거부됨")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            print("🔄 위치 권한 요청 중")
        @unknown default:
            break
        }
    }
    
    // MARK: - Data Loading
    private func loadLottoStores() {
        lottoAPIManager.fetchNearbyLottoStores(
            latitude: locationManager.location?.coordinate.latitude ?? 37.5666,
            longitude: locationManager.location?.coordinate.longitude ?? 126.9784,
            radius: 3000
        ) { [weak self] result in
            switch result {
            case .success(let stores):
                DispatchQueue.main.async {
                    self?.stores = stores
                    self?.markerManager.createMarkers(for: stores)
                    // LocationManager에 stores 전달하여 모니터링 시작
                    LocationManager.shared.startMonitoringStores(stores)
                    print("✅ 로드된 판매점 수: \(stores.count)")
                }
            case .failure(let error):
                print("❌ 판매점 로드 실패: \(error)")
            }
        }
    }
    
    // MARK: - Marker Management
    private func updateVisibleMarkers() {
        let visibleBounds = mapView.contentBounds
        
        // 현재 보이는 영역의 매장만 필터링
        let visibleStores = stores.filter { store in
            guard let latString = store.latitude,
                  let lngString = store.longitude,
                  let latitude = Double(latString),
                  let longitude = Double(lngString),
                  let storeId = store.id else {  // id도 안전하게 언래핑
                return false
            }
            let position = NMGLatLng(lat: latitude, lng: longitude)
            return visibleBounds.hasPoint(position)
        }
        
        // 보이지 않는 마커 제거
        visibleMarkers.forEach { (id, marker) in
            if !visibleStores.contains(where: { $0.id == id }) {
                marker.mapView = nil
                visibleMarkers.removeValue(forKey: id)
            }
        }
        
        // 새로운 마커 추가
        for store in visibleStores {
            if let storeId = store.id, visibleMarkers[storeId] == nil {  // id 안전하게 언래핑
                let marker = createMarker(for: store)
                visibleMarkers[storeId] = marker
            }
        }
    }
    
    private func createMarker(for store: LottoStore) -> NMFMarker {
        let marker = NMFMarker()
        
        guard let latString = store.latitude,
              let lngString = store.longitude,
              let latitude = Double(latString),
              let longitude = Double(lngString) else {
            marker.position = NMGLatLng(lat: 37.5666791, lng: 126.9782914)
            return marker
        }
        
        marker.position = NMGLatLng(lat: latitude, lng: longitude)
        marker.captionText = store.name
        
        // 마커 색상을 초록색으로 변경
        marker.iconTintColor = UIColor.systemGreen  // 또는 UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
        
        marker.mapView = mapView
        
        return marker
    }
    
    // MARK: - Navigation
    private func showStoreDetail(_ store: LottoStore) {
        // showStoreDetail 메서드 제거
    }
    
    // MARK: - Public Methods
    func displayStores(_ stores: [LottoStore]) {
        self.stores = stores
        markerManager.createMarkers(for: stores)
        startMonitoringStores()
    }
    
    func clearMarkers() {
        markerManager.removeAllMarkers()
    }
    
    // MARK: - Actions
    @objc private func currentLocationButtonTapped() {
        print("📍 현재 위치 버튼 탭")
        
        // 위치 권한 확인
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 위치 업데이트 시작
            locationManager.startUpdatingLocation()
            
            // 현재 위치로 지도 이동
            if let location = locationManager.location {
                print("📍 현재 위치로 이동: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                moveToLocation(location)
                loadLottoStores() // 주변 판매점 다시 로드
            } else {
                print("⚠️ 현재 위치를 찾을 수 없습니다")
                showAlert(message: "현재 위치를 찾을 수 없습니다.")
            }
            
        case .denied, .restricted:
            print("⚠️ 위치 권한이 없습니다")
            showLocationPermissionAlert()
            
        case .notDetermined:
            print("📍 위치 권한 요청")
            locationManager.requestWhenInUseAuthorization()
            
        @unknown default:
            break
        }
    }
    
    // 위치로 이동하는 메서드 수정
    private func moveToLocation(_ location: CLLocation) {
        let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: 15)
        cameraUpdate.animation = .easeIn
        cameraUpdate.animationDuration = 0.5
        mapView.moveCamera(cameraUpdate)
        
        // 현재 위치 오버레이 업데이트
        mapView.locationOverlay.location = coord
        mapView.locationOverlay.hidden = false
        
        print("✅ 지도 이동 완료: \(coord.lat), \(coord.lng)")
    }
    
    // MARK: - Private Methods
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "현재 위치를 확인하기 위해 위치 권한이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "오류 발생",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Monitoring Methods
    private func startMonitoringStores() {
        print("🔍 판매점 모니터링 시작...")
        monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        monitoredRegions.removeAll()
        
        guard let currentLocation = locationManager.location else {
              print("⚠️ 현재 위치를 찾을 수 없습니다")
              return
          }
        
        for store in stores {
            guard let latitude = store.latitude,
                  let longitude = store.longitude,
                  let lat = Double(latitude),
                  let lng = Double(longitude) else { 
                print("⚠️ 판매점 좌표 오류: \(store.name)")
                continue 
            }
            
            let storeLocation = CLLocation(latitude: lat, longitude: lng)
            let distance = currentLocation.distance(from: storeLocation)
            
            // 모니터링 반경 내에 있는 경우 알림 전송
            if distance <= monitoringRadius {
                   print("✅ 반경 내 매장 발견: \(store.name) (거리: \(Int(distance))m)")
               }
            
            // 지역 모니터링 설정
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let region = CLCircularRegion(center: coordinate,
                                        radius: monitoringRadius,
                                        identifier: store.id ?? "")
            
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            locationManager.startMonitoring(for: region)
            monitoredRegions.append(region)
        }
        
        print("✅ 총 \(monitoredRegions.count)개의 판매점 모니터링 시작")
    }
    
    // MARK: - Lotto Number Generation
    private func generateLottoNumbers() -> (numbers: [Int], specialNumbers: [Int]) {
        var numbers = Set<Int>()
        while numbers.count < 6 {
            numbers.insert(Int.random(in: 1...45))
        }
        
        let sortedNumbers = Array(numbers).sorted()
        
        // 70% 확률로 모든 번호를 특별 번호로 지정
        let shouldGenerateSpecial = Double.random(in: 0...1) < 0.7
        
        if shouldGenerateSpecial {
            // 모든 번호를 특별 번호로 지정
            return (sortedNumbers, sortedNumbers)
        }
        
        return (sortedNumbers, [])
    }

    
    // 에러 표시를 위한 헬퍼 메서드
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "알림",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    func loadNearbyStores(latitude: Double, longitude: Double) {
        lottoAPIManager.fetchNearbyLottoStores(
            latitude: latitude,
            longitude: longitude,
            radius: 3000 // 반경 설정 (미터 단위)
        ) { [weak self] result in
            switch result {
            case .success(let stores):
                DispatchQueue.main.async {
                    self?.stores = stores
                    self?.markerManager.createMarkers(for: stores)
                }
            case .failure(let error):
                print("❌ 판매점 로드 실패: \(error)")
            }
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 위치 권한 변경: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            // 권한을 받은 즉시 주변 판매점 로드
            loadLottoStores()
        case .denied, .restricted:
            showLocationPermissionAlert()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("📍 위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // 위치 업데이트
        moveToLocation(location)
        
        // 주변 판매점 확인
        LocationManager.shared.locationUpdateHandler?(location)
        
        // 위치 업데이트는 계속 유지
        // locationManager.stopUpdatingLocation() 제거
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
        showError(error)
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        let components = circularRegion.identifier.split(separator: "|")
        guard components.count == 2 else { return }
        
        let storeName = String(components[1])
        print("🎯 판매점 반경 진입: \(storeName)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("지역 모니터링 실패: \(error.localizedDescription)")
    }
}

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
    let mapView = NMFMapView()
    private let locationManager = CLLocationManager()
    private let lottoAPIManager = LottoAPIManager.shared
    private var stores: [LottoStore] = []
    private var visibleMarkers: [String: NMFMarker] = [:]
    private lazy var markerManager = MarkerManager(mapView: mapView)
    private let geocodingService = GeocodingService()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let monitoringRadius: CLLocationDistance = 1000 // 1km 반경
    private var monitoredRegions: [CLCircularRegion] = []
    private let alertManager = AlertManager.shared
    private var notificationCount: Int = 0 {
        didSet {
            updateNotificationButtonImage()
        }
    }
    
    // MARK: - UI Components
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "지역 이름으로 검색"
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 8
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .black
        
        let searchImageView = UIImageView(frame: CGRect(x: 8, y: 0, width: 20, height: 20))
        searchImageView.image = UIImage(systemName: "magnifyingglass")
        searchImageView.tintColor = .gray
        searchImageView.contentMode = .center
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        leftPaddingView.addSubview(searchImageView)
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowOpacity = 0.3
        textField.layer.shadowRadius = 4
        
        textField.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        return textField
    }()
    
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
    
    private let notificationButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "bell"), for: .normal)
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
        setupMapView()
        setupUI()
        setupLocationManager()
        setupActions()
        setupNotifications()
        requestNotificationPermission()
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
        
        // 델리게이트 설정
        mapView.addCameraDelegate(delegate: self)
        mapView.touchDelegate = self
    }
    
    private func setupUI() {
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
        
        view.addSubview(currentLocationButton)
        currentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(searchTextField.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(50)
        }
        
        view.addSubview(notificationButton)
        notificationButton.snp.makeConstraints { make in
            make.top.equalTo(currentLocationButton.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(50)
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 50
        
        // 위치 권한 요청
        locationManager.requestAlwaysAuthorization()
        
        // 알림 권한도 함께 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 알림 권한 허용됨")
            } else {
                print("❌ 알림 권한 거부됨: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    private func setupActions() {
        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonTapped), for: .touchUpInside)
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        searchTextField.delegate = self
        requestNotificationPermission()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationCountChange),
            name: .notificationCountDidChange,
            object: nil
        )
    }
    
    private func requestNotificationPermission() {
        alertManager.requestNotificationPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.alertManager.showPermissionAlert(on: self)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadLottoStores() {
        guard let currentLocation = LocationManager.shared.currentLocation else {
            print("⚠️ 현재 위치를 찾을 수 없습니다")
            return
        }
        
        LottoAPIManager.shared.fetchNearbyLottoStores(
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude,
            radius: 1000
        ) { [weak self] result in
            switch result {
            case .success(let stores):
                DispatchQueue.main.async {
                    self?.stores = stores  // stores 배열 업데이트
                    self?.markerManager.createMarkers(for: stores)  // 마커 생성
                    self?.startMonitoringStores()  // 판매점 모니터링 시작
                }
            case .failure(let error):
                print("❌ 로또 판매점 조회 실패: \(error.localizedDescription)")
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
                  let longitude = Double(lngString) else {
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
            if visibleMarkers[store.id] == nil {
                let marker = createMarker(for: store)
                visibleMarkers[store.id] = marker
            }
        }
    }
    
    private func createMarker(for store: LottoStore) -> NMFMarker {
        let marker = NMFMarker()
        
        // String을 Double로 변환
        guard let latString = store.latitude,
              let lngString = store.longitude,
              let latitude = Double(latString),
              let longitude = Double(lngString) else {
            // 좌표가 없는 경우 기본 위치 설정 (예: 서울시청)
            marker.position = NMGLatLng(lat: 37.5666791, lng: 126.9782914)
            return marker
        }
        
        marker.position = NMGLatLng(lat: latitude, lng: longitude)
        marker.captionText = store.name
        marker.mapView = mapView
        
        // 마커 터치 이벤트
        marker.touchHandler = { [weak self] _ in
            self?.showStoreDetail(store)
            return true
        }
        
        return marker
    }
    
    // MARK: - Navigation
    private func showStoreDetail(_ store: LottoStore) {
        let detailVC = LottoMapViewController()
        detailVC.configure(with: store)  // store 정보 전달
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Public Methods
    func displayStores(_ stores: [LottoStore]) {
        print("📍 마커 생성 시작: \(stores.count)개의 판매점")
        self.stores = stores
        markerManager.removeAllMarkers()
        markerManager.createMarkers(for: stores)
        startMonitoringStores()
    }
    
    func clearMarkers() {
        markerManager.removeAllMarkers()
    }
    
    // 카메라 이동이 끝났을 때 주변 판매점 로드
    func mapView(_ mapView: NMFMapView, cameraDidStopMoving reason: Int) {
        let center = mapView.cameraPosition.target
        if let lottoMapVC = parent as? LottoMapViewController {
            lottoMapVC.loadNearbyStores(latitude: center.lat, longitude: center.lng)
        }
    }
    
    // MARK: - Actions
    @objc private func currentLocationButtonTapped() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 현재 위치 업데이트 시작
            LocationManager.shared.startUpdatingLocation()
            if let location = LocationManager.shared.currentLocation {
                moveToLocation(location)
                // 현재 위치 기반으로 주변 판매점 다시 로드
                if let lottoMapVC = parent as? LottoMapViewController {
                    lottoMapVC.loadNearbyStores(latitude: location.coordinate.latitude,
                                             longitude: location.coordinate.longitude)
                }
            }
        case .denied, .restricted:
            showLocationPermissionAlert()
        case .notDetermined:
            LocationManager.shared.requestLocationAuthorization()
        @unknown default:
            break
        }
    }
    
    @objc private func notificationButtonTapped() {
        let historyVC = LottoHistoryViewController()
        navigationController?.pushViewController(historyVC, animated: true)
    }
    
    // 위치 이동 메서드 추가
    func moveToLocation(_ location: CLLocation) {
        let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: 15)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        
        // 현재 위치 오버레이 표시
        mapView.locationOverlay.location = coord
        mapView.locationOverlay.hidden = false
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
        // 기존 모니터링 중인 지역 제거
        monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        monitoredRegions.removeAll()
        
        var monitoredCount = 0
        
        // 현재 위치 확인
        guard let currentLocation = LocationManager.shared.currentLocation else {
            print("⚠️ 현재 위치를 찾을 수 없습니다")
            return
        }
        
        print("📍 현재 위치: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
        
        // 새로운 판매점 모니터링 시작
        for store in stores {
            guard let latitude = Double(store.latitude ?? ""),
                  let longitude = Double(store.longitude ?? "") else { 
                print("⚠️ 판매점 좌표 오류: \(store.name)")
                continue 
            }
            
            let storeLocation = CLLocation(latitude: latitude, longitude: longitude)
            let distance = currentLocation.distance(from: storeLocation)
            
            // 모니터링 반경 내에 있는 경우
            if distance <= monitoringRadius {
                print("✅ 반경 내 매장 발견: \(store.name) (거리: \(Int(distance))m)")
                
                // 즉시 알림 전송
                DispatchQueue.main.async { [weak self] in
                    self?.sendLottoNumberNotification(for: store)
                }
            }
            
            // 지역 모니터링 설정
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = CLCircularRegion(center: coordinate,
                                        radius: monitoringRadius,
                                        identifier: store.id)
            
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            locationManager.startMonitoring(for: region)
            monitoredRegions.append(region)
            monitoredCount += 1
        }
        
        print("✅ 총 \(monitoredCount)개의 판매점 모니터링 시작")
    }
    
    // MARK: - Lotto Number Generation
    private func generateLottoNumbers() -> [Int] {
        var numbers = Set<Int>()
        while numbers.count < 6 {
            numbers.insert(Int.random(in: 1...45))
        }
        return Array(numbers).sorted()
    }
    
    // MARK: - Notification Methods
    private func sendLottoNumberNotification(for store: LottoStore) {
        guard let currentLocation = LocationManager.shared.currentLocation,
              let latitude = Double(store.latitude ?? ""),
              let longitude = Double(store.longitude ?? "") else {
            print("⚠️ 위치 정보 누락")
            return
        }
        
        let storeLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distance = currentLocation.distance(from: storeLocation)
        let distanceInMeters = Int(distance)
        
        print("📍 알림 전송 시도: \(store.name) (거리: \(distanceInMeters)m)")
        
        let content = UNMutableNotificationContent()
        content.title = "🎱 로또 번호 추천"
        content.body = """
            \(store.name) 근처입니다! (약 \(distanceInMeters)m)
            주소: \(store.address)
            추천 번호: \(generateLottoNumbers().map { String(format: "%02d", $0) }.joined(separator: ", "))
            """
        content.sound = UNNotificationSound.default
        
        // 즉시 알림을 위한 트리거
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알림 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 알림 전송 성공: \(store.name)")
            }
        }
    }
    
    @objc private func handleNotificationCountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            if let count = notification.userInfo?["count"] as? Int {
                self?.notificationCount = count
            }
        }
    }
    
    private func updateNotificationButtonImage() {
        DispatchQueue.main.async { [weak self] in
            let imageName = self?.notificationCount ?? 0 > 0 ? "bell.badge" : "bell"
            self?.notificationButton.setImage(UIImage(systemName: imageName), for: .normal)
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
        
        // 주변 판매점 로드 및 모니터링 시작
        loadLottoStores()
        startMonitoringStores()
        
        // 위치 업데이트 중지
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
        showError(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let store = stores.first(where: { $0.id == region.identifier }) else { return }
        print("🎯 판매점 반경 진입: \(store.name)")
        sendLottoNumberNotification(for: store)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("지역 모니터링 실패: \(error.localizedDescription)")
    }
}

// MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let searchText = textField.text?.trimmingCharacters(in: .whitespaces),
              !searchText.isEmpty else { return true }
        
        // 검색어로 필터링
        let filteredStores = stores.filter { store in
            store.name.contains(searchText) || store.address.contains(searchText)
        }
        
        if let firstStore = filteredStores.first,
           let latString = firstStore.latitude,
           let lngString = firstStore.longitude,
           let latitude = Double(latString),
           let longitude = Double(lngString) {
            let coord = NMGLatLng(lat: latitude, lng: longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: 15)
            mapView.moveCamera(cameraUpdate)
        }
        
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - NMFMapViewCameraDelegate
extension MapViewController: NMFMapViewCameraDelegate {
    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        // updateVisibleMarkers() 호출 제거
    }
}

// MARK: - NMFMapViewTouchDelegate
extension MapViewController: NMFMapViewTouchDelegate {
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng) {
        searchTextField.resignFirstResponder()
    }
}

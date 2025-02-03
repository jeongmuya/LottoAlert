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
    private let alertManager = AlertManager.shared
    private var notificationCount: Int = 0 {
        didSet {
            updateNotificationButtonImage()
        }
    }
    // 판매점별 마지막 알림 시간을 저장
    private var lastNotificationTimes: [String: Date] = [:]
    private let minimumNotificationInterval: TimeInterval = 300 // 5분으로 수정
    
    // MARK: - UI Components
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "지역 이름으로 검색"
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 8
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .black
        textField.returnKeyType = .search  // 리턴 키 타입 변경
        
        // 검색 아이콘 추가
        let searchImageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchImageView.tintColor = .gray
        searchImageView.contentMode = .center
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        leftView.addSubview(searchImageView)
        searchImageView.center = leftView.center
        textField.leftView = leftView
        textField.leftViewMode = .always
        
        // 그림자 최적화
        textField.layer.shadowPath = UIBezierPath(roundedRect: textField.bounds, cornerRadius: 8).cgPath
        textField.layer.shouldRasterize = true
        textField.layer.rasterizationScale = UIScreen.main.scale
        
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
        setupMarkerManager()
        setupLocationManager()
        setupActions()
        setupNotifications()
        requestNotificationPermission()
        
        // 위치 권한 확인 및 위치 업데이트 시작
        checkLocationAuthorization()
        loadLottoStores()
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
        mapView.addCameraDelegate(delegate: self)  // delegate: 파라미터 명시
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
        
        // 검색 필드 최적화
        searchTextField.delegate = self
        searchTextField.autocorrectionType = .no
        searchTextField.spellCheckingType = .no
        searchTextField.enablesReturnKeyAutomatically = true
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
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        searchTextField.delegate = self
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
        // 클로저를 별도의 메서드로 분리
        let completionHandler: (Bool) -> Void = { [weak self] granted in
            guard let self = self else { return }
            
            if !granted {
                DispatchQueue.main.async {
                    self.alertManager.showPermissionAlert(on: self)
                }
            }
        }
        
        // 명시적인 파라미터로 전달
        alertManager.requestNotificationPermission(completionHandler: completionHandler)
    }
    
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
        ) { [weak self] (result: Result<[LottoStore], Error>) in  // 타입 명시
            switch result {
            case .success(let stores):
                self?.stores = stores
                self?.markerManager.createMarkers(for: stores)
                self?.startMonitoringStores()
            case .failure(let error):
                print("Error loading stores: \(error)")
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
    
    @objc private func notificationButtonTapped() {
        let historyVC = LottoHistoryViewController()
        navigationController?.pushViewController(historyVC, animated: true)
        notificationCount = 0  // 카운트 초기화
        updateNotificationButtonImage()  // 버튼 이미지 업데이트
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
        
        guard let currentLocation = LocationManager.shared.currentLocation else {
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
                DispatchQueue.main.async { [weak self] in
                    self?.sendLottoNumberNotification(for: store)
                }
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
    
    // MARK: - Notification Methods
    private func sendLottoNumberNotification(for store: LottoStore) {
        // 마지막 알림 시간 확인
        if let lastTime = lastNotificationTimes[store.id ?? ""],
           Date().timeIntervalSince(lastTime) < minimumNotificationInterval {
            print("⏱ \(store.name)의 다음 알림까지 대기 중")
            return
        }

        guard let currentLocation = LocationManager.shared.currentLocation,
              let latitude = Double(store.latitude ?? ""),
              let longitude = Double(store.longitude ?? "") else {
            print("⚠️ 위치 정보 누락")
            return
        }
        
        let storeLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distance = currentLocation.distance(from: storeLocation)
        let distanceInMeters = Int(distance)
        
        // 추천 번호 생성
        let (recommendedNumbers, specialNumbers) = generateLottoNumbers()
        
        // 알림 메시지에 특별 번호 표시
        let numbersText = recommendedNumbers.map { number -> String in
            let formatted = String(format: "%02d", number)
            return specialNumbers.contains(number) ? "✨\(formatted)✨" : formatted
        }.joined(separator: ", ")
        
        print("📍 알림 전송 시도: \(store.name) (거리: \(distanceInMeters)m)")
        
        let content = UNMutableNotificationContent()
        content.title = "🎱 로또 번호 추천"
        content.body = """
            \(store.name) 근처입니다! (약 \(distanceInMeters)m)
            주소: \(store.address)
            추천 번호: \(numbersText)
            """
        content.sound = UNNotificationSound.default
        
        // 즉시 알림을 위한 트리거
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // completionHandler를 별도의 메서드로 분리
        UNUserNotificationCenter.current().add(
            request,
            withCompletionHandler: makeNotificationCompletionHandler(for: store, numbers: recommendedNumbers, special: specialNumbers)
        )
    }
    
    private func makeNotificationCompletionHandler(
        for store: LottoStore,
        numbers: [Int],
        special: [Int]
    ) -> ((Error?) -> Void) {
        return { [weak self] error in
            if let error = error {
                print("❌ 알림 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 알림 전송 성공: \(store.name)")
                self?.handleSuccessfulNotification(store: store, numbers: numbers, special: special)
            }
        }
    }
    
    private func handleSuccessfulNotification(store: LottoStore, numbers: [Int], special: [Int]) {
        DispatchQueue.main.async { [weak self] in
            self?.lastNotificationTimes[store.id ?? ""] = Date()
            self?.notificationCount += 1
            self?.updateNotificationButtonImage()
            
            let recommendation = LottoRecommendation(
                numbers: numbers,
                storeName: store.name,
                specialNumbers: special
            )
            self?.saveRecommendation(recommendation)
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
            // 알림이 있을 때는 채워진 벨 아이콘을 빨간색으로
            if self?.notificationCount ?? 0 > 0 {
                let image = UIImage(systemName: "bell.fill")
                self?.notificationButton.setImage(image, for: .normal)
                self?.notificationButton.tintColor = .systemRed
            } else {
                // 알림이 없을 때는 기본 벨 아이콘을 파란색으로
                let image = UIImage(systemName: "bell")
                self?.notificationButton.setImage(image, for: .normal)
                self?.notificationButton.tintColor = .systemBlue
            }
        }
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
            radius: 3000
        ) { [weak self] result in
            switch result {
            case .success(let stores):
                self?.stores = stores
                self?.markerManager.createMarkers(for: stores)
                self?.startMonitoringStores()
            case .failure(let error):
                print("Error loading stores: \(error)")
            }
        }
    }
    
    private func saveRecommendation(_ recommendation: LottoRecommendation) {
        if let data = UserDefaults.standard.data(forKey: "lottoRecommendations"),
           var recommendations = try? JSONDecoder().decode([LottoRecommendation].self, from: data) {
            recommendations.insert(recommendation, at: 0)
            if recommendations.count > 50 {
                recommendations = Array(recommendations.prefix(50))
            }
            if let encoded = try? JSONEncoder().encode(recommendations) {
                UserDefaults.standard.set(encoded, forKey: "lottoRecommendations")
            }
        } else {
            if let encoded = try? JSONEncoder().encode([recommendation]) {
                UserDefaults.standard.set(encoded, forKey: "lottoRecommendations")
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
        guard let store = stores.first(where: { String($0.number) == region.identifier }) else { return }
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
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            showSearchViewController()
            return false
        }
        return true
    }
    
    private func showSearchViewController() {
        let searchVC = LottoStoreSearchViewController()
        searchVC.configure(with: stores)
        searchVC.delegate = self
        searchVC.modalPresentationStyle = .fullScreen
        present(searchVC, animated: true)
    }
}

// MARK: - NMFMapViewCameraDelegate
extension MapViewController: NMFMapViewCameraDelegate {
    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        // 카메라 이동 시 필요한 로직 구현
    }
}

// MARK: - NMFMapViewTouchDelegate
extension MapViewController: NMFMapViewTouchDelegate {
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng) {
        searchTextField.resignFirstResponder()
    }
}

// MARK: - MapViewControllerDelegate
extension MapViewController: MapViewControllerDelegate {
    func mapViewController(_ controller: LottoMapViewController, didMoveCameraTo position: NMGLatLng) {
        loadNearbyStores(latitude: position.lat, longitude: position.lng)
    }
}

// MARK: - LottoStoreSearchViewControllerDelegate
extension MapViewController: LottoStoreSearchViewControllerDelegate {
    func searchViewController(_ controller: LottoStoreSearchViewController, didSelectStore store: LottoStore) {
        guard let latitude = Double(store.latitude ?? ""),
              let longitude = Double(store.longitude ?? "") else { return }
        
        let coord = NMGLatLng(lat: latitude, lng: longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: 15)
        mapView.moveCamera(cameraUpdate)
    }
}

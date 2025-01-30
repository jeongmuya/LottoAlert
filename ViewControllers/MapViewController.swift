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

class MapViewController: UIViewController {
    
    // MARK: - Properties
    let mapView = NMFMapView()
    private let locationManager = CLLocationManager()
    private let lottoAPIManager = LottoAPIManager.shared
    private var stores: [LottoStore] = []
    private var visibleMarkers: [String: NMFMarker] = [:]
    private lazy var markerManager = MarkerManager(mapView: mapView)
    private let geocodingService = GeocodingService()
    
    // MARK: - UI Components
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "지역 이름으로 검색"
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 8
        let searchImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        searchImageView.image = UIImage(systemName: "magnifyingglass")
        searchImageView.tintColor = .gray
        searchImageView.contentMode = .center
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        leftPaddingView.addSubview(searchImageView)
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowOpacity = 0.2
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupUI()
        setupLocationManager()
        setupActions()
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
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupActions() {
        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonTapped), for: .touchUpInside)
        searchTextField.delegate = self
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
        self.stores = stores
        markerManager.removeAllMarkers()  // 기존 마커 제거
        markerManager.createMarkers(for: stores)
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
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showLocationPermissionAlert()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 위치 업데이트
        moveToLocation(location)
        
        // 첫 위치 업데이트 후에만 주변 판매점 로드
        if mapView.locationOverlay.hidden {
            loadLottoStores()
        }
        
        // 위치 업데이트 중지
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
        showError(error)
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

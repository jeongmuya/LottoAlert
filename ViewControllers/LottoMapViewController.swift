//
//  LottoMapViewController.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/21/25.
//

import UIKit
import NMapsMap

class LottoMapViewController: UIViewController {
    private var mapViewController: MapViewController!
    private var lottoStores: [LottoStore] = []
    private var selectedStore: LottoStore?
    
    // 로딩 인디케이터
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let geocodingService = GeocodingService()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocation()
    }
    
    private func setupUI() {
        // MapViewController 설정
        mapViewController = MapViewController()
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mapViewController.didMove(toParent: self)
        print("✅ MapViewController가 LottoMapViewController의 자식으로 추가됨")
        
        // 로딩 인디케이터 설정
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupLocation() {
        LocationManager.shared.authorizationStatusHandler = { [weak self] status in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                // 권한이 있으면 바로 위치 업데이트 시작
                LocationManager.shared.startUpdatingLocation()
            case .denied, .restricted:
                self?.showLocationPermissionAlert()
            default:
                break
            }
        }
        
        LocationManager.shared.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            
            // 지도 이동
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: 15)
            cameraUpdate.animation = .easeIn
            self.mapViewController.mapView.moveCamera(cameraUpdate)
            
            // 현재 위치 오버레이 표시
            self.mapViewController.mapView.locationOverlay.location = coord
            self.mapViewController.mapView.locationOverlay.hidden = false
            
            // 현재 위치 기반으로 주변 판매점 로드
            self.loadNearbyStores(latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude)
        }
        
        // 앱 시작 시 바로 위치 권한 요청
        LocationManager.shared.requestLocationAuthorization()
    }
    
    func loadNearbyStores(latitude: Double, longitude: Double) {
        DispatchQueue.main.async {
            self.loadingIndicator.startAnimating()
            // 기존 마커 제거
            self.mapViewController.clearMarkers()
        }
        
        LottoAPIManager.shared.fetchNearbyLottoStores(
            latitude: latitude,
            longitude: longitude,
            radius: 3000  // 3km 반경 내 검색
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let stores):
                print("로또 판매점 데이터 수신: \(stores.count)개")
                self.lottoStores = stores
                Task {
                    await self.geocodeStores(stores)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showError(error)
                }
            }
        }
    }
    
    func geocodeStores(_ stores: [LottoStore]) async {
        print("🌍 지오코딩 시작: \(stores.count)개의 판매점")
        var geocodedStores: [LottoStore] = []
        let totalCount = stores.count
        
        for (index, var store) in stores.enumerated() {
            do {
                print("🔄 지오코딩 진행중: \(index + 1)/\(totalCount) - \(store.name)")
                let coordinate = try await geocodingService.geocodeAddress(store.address)
                store.latitude = String(coordinate.latitude)
                store.longitude = String(coordinate.longitude)
                geocodedStores.append(store)
                
                // 일정 개수의 판매점이 모이면 한 번에 업데이트
                if geocodedStores.count % 5 == 0 || index == totalCount - 1 {
                    DispatchQueue.main.async {
                        print("📍 마커 일괄 추가: \(geocodedStores.count)개")
                        self.mapViewController.displayStores(geocodedStores)
                    }
                }
                
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                print("❌ 지오코딩 실패: \(store.name) - \(error.localizedDescription)")
                continue
            }
        }
        
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            self.lottoStores = geocodedStores
            print("🎯 모든 판매점 표시 완료: \(geocodedStores.count)개")
            self.mapViewController.displayStores(geocodedStores)
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "주변 로또 판매점을 찾기 위해 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
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
    
    // store 정보를 설정하는 메서드
    func configure(with store: LottoStore) {
        selectedStore = store
        // 필요한 UI 업데이트
    }
}

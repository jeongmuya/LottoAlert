//
//  LottoMapViewController.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/21/25.
//

import UIKit
import NMapsMap
import SnapKit

class LottoMapViewController: UIViewController, NMFMapViewCameraDelegate {
    // MARK: - Properties
    private let mapView = NMFMapView()  // 직접 맵뷰를 가지도록 수정
    private var lottoStores: [LottoStore] = []
    private var selectedStore: LottoStore?
    private let geocodingService = GeocodingService()
    private var currentMarkers: [NMFMarker] = []  // 마커 배열 추가
    private lazy var markerManager = MarkerManager(mapView: mapView)
    
    // MARK: - UI Components
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MapViewController와의 통신을 위한 델리게이트 패턴 추가
    weak var delegate: MapViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocation()
        mapView.addCameraDelegate(delegate: self)  // 카메라 델리게이트 설정
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // 맵뷰 설정
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
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
                LocationManager.shared.startUpdatingLocation()
            case .denied, .restricted:
                self?.showLocationPermissionAlert()
            default:
                break
            }
        }
        
        LocationManager.shared.locationUpdateHandler = { [weak self] location in
            self?.loadNearbyStores(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        
        LocationManager.shared.requestLocationAuthorization()
    }
    
    // MARK: - Public Methods
    func configure(with store: LottoStore) {
        selectedStore = store
        markerManager.createSingleMarker(for: store)
    }
    
    // MARK: - Private Methods
    private func loadNearbyStores(latitude: Double, longitude: Double) {
        loadingIndicator.startAnimating()
        
        LottoAPIManager.shared.fetchNearbyLottoStores(
            latitude: latitude,
            longitude: longitude,
            radius: 3000
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let stores):
                    self.lottoStores = stores
                    self.displayStores(stores)
                case .failure(let error):
                    print("Error loading stores: \(error)")
                    self.showError(error)
                }
            }
        }
    }
    
    private func displayStores(_ stores: [LottoStore]) {
        markerManager.createMarkers(for: stores)
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "주변 로또 판매점을 찾기 위해 위치 권한이 필요합니다.",
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
    
    // NMFMapViewCameraDelegate 메서드
    func mapView(_ mapView: NMFMapView, cameraDidStopMoving reason: Int) {
        let center = mapView.cameraPosition.target
        delegate?.mapViewController(self, didMoveCameraTo: center)
    }
}

// 델리게이트 프로토콜 정의
protocol MapViewControllerDelegate: AnyObject {
    func mapViewController(_ controller: LottoMapViewController, didMoveCameraTo position: NMGLatLng)
}

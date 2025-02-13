//
//  MapViewController.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/11/25.
//

import UIKit
import SnapKit
import MapKit
import CoreLocation


class MapViewController: UIViewController {
    
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager() // 위치 관리자
    
    private lazy var myLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = UIColor(red: 245/255, green: 220/255, blue: 37/255, alpha: 1.0) 
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.addTarget(self, action: #selector(myLocationButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        AnnotationManager.shared.loadStoresFromJSON()
        setupLocationManager() // 위치 관리자 설정
        setupMapView()
        addAnnotations()
        setupMyLocationButton()
        locationManager.startUpdatingLocation()
        // 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한이 허용되었습니다.")
            } else {
                print("알림 권한이 거부되었습니다.")
            }
        }
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        
    }
    
    
    
    private func setupMapView() {
        view.addSubview(mapView)
        
        AlertManager.shared.requestNotificationPermission()
        mapView.showsUserLocation = true // 사용자 위치 표시
        mapView.setUserTrackingMode(.follow, animated: true) // 사용자 위치 트랙킹
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() // 위치 권한 요청
    }
    
    private func addAnnotations() {
        // AnnotationManager에서 어노테이션 가져오기
        let annotations = AnnotationManager.shared.loadStores() // 메서드 이름 수정
        mapView.addAnnotations(annotations)
    }
    
    private func setupMyLocationButton() {
        view.addSubview(myLocationButton)
        myLocationButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.width.height.equalTo(50)
        }
    }
    
    // 버튼 탭 액션
    @objc private func myLocationButtonTapped() {
        if let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
}

// 위치 관리자 델리게이트 추가
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
    }
    

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation = true
        case .denied, .restricted:
            print("위치 권한이 거부되었습니다.")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

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
        mapView.delegate = self
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
    
    
    
    // 경로 찾기 함수 추가
    private func findRoute(to destination: CLLocationCoordinate2D) {
        guard let userLocation = locationManager.location?.coordinate else {
            print("사용자 위치를 찾을 수 없습니다.")
            return
        }
        
        // 기존 경로가 있다면 제거
        mapView.overlays.forEach { mapView.removeOverlay($0) }
        
        let sourcePlacemark = MKPlacemark(coordinate: userLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] (response, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("경로 계산 오류: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else { return }
            
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            // 경로가 모두 보이도록 지도 영역 조정
            let rect = route.polyline.boundingMapRect
            self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
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


// MKMapViewDelegate 확장 추가
extension MapViewController: MKMapViewDelegate {
    // 경로 스타일 지정
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(red: 245/255, green: 220/255, blue: 37/255, alpha: 1.0) // 로또 앱 테마 색상으로 설정
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // 어노테이션 탭 처리
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        // 사용자 위치 마커가 아닌 경우에만 경로 표시
        if annotation is MKUserLocation {
            return
        }
        
        // 선택된 마커까지의 경로 찾기
        findRoute(to: annotation.coordinate)
    }
}


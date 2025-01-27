//
//  MarkerManager.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/21/25.
//

import UIKit
import SwiftUI
import NMapsMap
import SnapKit
import CoreLocation

class MarkerManager {
    private let mapView: NMFMapView
    private var markers: [String: NMFMarker] = [:] // id를 키로 사용
    
    init(mapView: NMFMapView) {
        self.mapView = mapView
    }
    
    // 테스트용 단일 마커 생성
    func createTestMarker() {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: 37.4563, lng: 126.6489)
        marker.captionText = "테스트 복권방"
        
        // 마커 스타일 설정
        marker.iconImage = NMF_MARKER_IMAGE_BLACK
        marker.iconTintColor = .red
        marker.width = 25
        marker.height = 40
        
        // 캡션 스타일 설정
        marker.captionTextSize = 14
        marker.captionColor = .black
        marker.captionHaloColor = .white
        
        // 마커 클릭 이벤트
        marker.touchHandler = { [weak self] overlay in
            print("복권방이 선택되었습니다")
            return true
        }
        
        // 지도에 마커 표시
        marker.mapView = self.mapView
        markers[marker.captionText] = marker
        
        // 해당 위치로 카메라 이동
        let cameraUpdate = NMFCameraUpdate(scrollTo: marker.position)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    func createMarkers(for stores: [LottoStore]) {
        createMarkers(for: stores, on: self.mapView)
    }
    
    func createMarkers(for stores: [LottoStore], on mapView: NMFMapView) {
        // 기존 마커 제거
        removeAllMarkers()
        
        print("📍 마커 생성 시작: \(stores.count)개의 판매점")
        
        for store in stores {
            guard let latitude = Double(store.latitude ?? ""),
                  let longitude = Double(store.longitude ?? "") else {
                print("⚠️ 좌표 변환 실패: \(store.name)")
                continue
            }
            
            print("✅ 마커 생성: \(store.name) at (\(latitude), \(longitude))")
            
            let position = NMGLatLng(lat: latitude, lng: longitude)
            let marker = NMFMarker()
            marker.position = position
            marker.mapView = mapView
            
            // 마커 정보 설정
            marker.captionText = store.name
            marker.captionColor = .black
            marker.captionHaloColor = .white
            marker.captionTextSize = 14
            
            markers[store.id] = marker
        }
        
        print("✅ 총 \(markers.count)개의 마커 생성 완료")
    }
    
    private func showStoreInfo(_ store: LottoStore) {
        if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController {
            let alert = UIAlertController(
                title: store.name,
                message: """
                    주소: \(store.address)
                    """,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            topViewController.present(alert, animated: true)
        }
    }
    
    private func fitMapToMarkers() {
        guard !markers.isEmpty else { return }
        
        let positions = markers.values.map { $0.position }
        var minLat = positions[0].lat
        var maxLat = positions[0].lat
        var minLng = positions[0].lng
        var maxLng = positions[0].lng
        
        positions.forEach { position in
            minLat = min(minLat, position.lat)
            maxLat = max(maxLat, position.lat)
            minLng = min(minLng, position.lng)
            maxLng = max(maxLng, position.lng)
        }
        
        let bounds = NMGLatLngBounds(
            southWest: NMGLatLng(lat: minLat, lng: minLng),
            northEast: NMGLatLng(lat: maxLat, lng: maxLng)
        )
        
        let cameraUpdate = NMFCameraUpdate(fit: bounds, padding: 50)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        
        print("🎯 지도 영역 조정 완료")
    }
    
    func removeAllMarkers() {
        markers.values.forEach { $0.mapView = nil }
        markers.removeAll()
    }
    
    func addMarkers(for stores: [LottoStore]) {
        createMarkers(for: stores)
    }
}

// UIViewController 확장 - 최상위 뷰컨트롤러 찾기
extension UIViewController {
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController ?? navigation
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController ?? tab
        }
        return self
    }
}

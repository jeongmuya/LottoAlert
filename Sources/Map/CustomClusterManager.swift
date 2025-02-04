//
//  CustomClusterManager.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/4/25.
//
//  네이버 지도에 마커를 추가하고 클러스터링을 관리하는 클래스


import Foundation
import NMapsMap
import CoreLocation


class CustomClusterManager {
    private let mapView: NMFMapView
    private var markers: [NMFMarker] = []
    
    init(mapView: NMFMapView) {
        self.mapView = mapView
    }
    
    func addMarkers(for stores: [LottoStore]) {
        clearMarkers()
        
        stores.forEach { store in
            guard let latitude = Double(store.latitude ?? ""),
                  let longitude = Double(store.longitude ?? "") else { return }
            
            let marker = NMFMarker(position: NMGLatLng(lat: latitude, lng: longitude))
            marker.captionText = store.name
            marker.mapView = mapView
            markers.append(marker)
        }
        
        clusterMarkers()
    }
    
    private func clusterMarkers() {
        let clusterDistance: Double = 50.0 // 클러스터링 거리 기준 (미터)
        
        for i in 0..<markers.count {
            let marker1 = markers[i]
            for j in (i + 1)..<markers.count {
                let marker2 = markers[j]
                let distance = calculateDistance(marker1.position, marker2.position)
                if distance < clusterDistance {
                    // 마커를 클러스터링 처리
                    marker2.mapView = nil
                }
            }
        }
    }
    
    private func calculateDistance(_ pos1: NMGLatLng, _ pos2: NMGLatLng) -> Double {
        let location1 = CLLocation(latitude: pos1.lat, longitude: pos1.lng)
        let location2 = CLLocation(latitude: pos2.lat, longitude: pos2.lng)
        return location1.distance(from: location2)
    }
    
    func clearMarkers() {
        markers.forEach { $0.mapView = nil}
        markers.removeAll()
    }
}


//CustomClusterManager 클래스: 네이버 지도에 마커를 추가하고 클러스터링을 관리하는 클래스입니다.
//addMarkers 메서드: LottoStore 객체 리스트를 받아 마커를 생성하고 클러스터링을 수행합니다.
//clusterMarkers 메서드: 간단한 거리 기반 클러스터링을 수행하여 가까운 마커를 그룹화합니다. 클러스터링 거리 기준은 clusterDistance로 설정되어 있습니다.
//calculateDistance 메서드: 두 위치 간의 거리를 계산하여 클러스터링에 사용합니다.
//clearMarkers 메서드: 기존 마커를 모두 제거합니다.

//
//  MarkerManager.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/21/25.
//

import UIKit
import NMapsMap
import CoreLocation

class MarkerManager: NSObject {
    // MARK: - Properties
    private let mapView: NMFMapView
    private var markers: [NMFMarker] = []
    private var clusters: [NMFMarker] = []
    
    // MARK: - Constants
    private enum ClusterSize {
        static let small = 10
        static let medium = 100
        static let large = 500
        static let clusteringDistance: Double = 100.0 // 클러스터링 거리 (미터)
    }
    
    // MARK: - Initialization
    init(mapView: NMFMapView) {
        self.mapView = mapView
        super.init()
        setupMapView()
        setupMapViewDelegate()
    }
    
    private func setupMapView() {
        mapView.minZoomLevel = 6
        mapView.maxZoomLevel = 18
    }
    
    private func setupMapViewDelegate() {
        // 지도 줌 레벨 변경 시 클러스터링 업데이트
        mapView.addCameraDelegate(delegate: self)
    }
    
    // MARK: - Public Methods
    
    func clearMarkers() {
        markers.forEach { $0.mapView = nil }
        markers.removeAll()
        clusters.forEach { $0.mapView = nil }
        clusters.removeAll()
    }
    
    func removeAllMarkers() {
        clearMarkers()
    }
    
    // MARK: - Private Methods
    func createMarkers(for stores: [LottoStore]) {
        clearMarkers()
        
        // 마커 생성 및 즉시 지도에 표시
        stores.forEach { store in
            if let marker = createMarker(for: store) {
                marker.mapView = mapView  // 즉시 지도에 표시
                markers.append(marker)
            }
        }
    }
    
    
    private func createMarker(for store: LottoStore) -> NMFMarker? {
        guard let latitude = Double(store.latitude ?? ""),
              let longitude = Double(store.longitude ?? "") else { return nil }
        
        let marker = NMFMarker(position: NMGLatLng(lat: latitude, lng: longitude))
    
    
            marker.captionText = store.name
            marker.captionTextSize = 12
            marker.captionColor = .black
            marker.captionHaloColor = .white
            marker.width = 30
            marker.height = 40
            // 마커 이미지 설정
            // marker.iconImage = NMFOverlayImage(name: "marker_icon")
            
            return marker
        
    }
    
    private func updateClustering() {
        // 기존 클러스터 제거
        clusters.forEach { $0.mapView = nil }
        clusters.removeAll()
        
        // 모든 마커 숨기기
        markers.forEach { $0.mapView = nil }
        
        // 현재 줌 레벨에 따라 클러스터링 여부 결정
        if mapView.zoomLevel < 13 {
            createClusters()
        } else {
            // 줌 레벨이 높으면 개별 마커 표시
            markers.forEach { $0.mapView = mapView }
        }
    }
    
    private func createClusters() {
        var processedMarkers = Set<NMFMarker>()
        var clusterGroups: [[NMFMarker]] = []
        
        // 마커들을 거리에 따라 그룹화
        for marker in markers where !processedMarkers.contains(marker) {
            var cluster: [NMFMarker] = [marker]
            processedMarkers.insert(marker)
            
            for otherMarker in markers where !processedMarkers.contains(otherMarker) {
                let distance = calculateDistance(marker.position, otherMarker.position)
                if distance <= ClusterSize.clusteringDistance {
                    cluster.append(otherMarker)
                    processedMarkers.insert(otherMarker)
                }
            }
            
            if cluster.count > 1 {
                clusterGroups.append(cluster)
            } else {
                // 단일 마커는 지도에 직접 표시
                marker.mapView = mapView
            }
        }
        
        // 클러스터 마커 생성
        for group in clusterGroups {
            createClusterMarker(for: group)
        }
    }
    
    private func createClusterMarker(for group: [NMFMarker]) {
        // 클러스터의 중심점 계산
        let centerLat = group.map { $0.position.lat }.reduce(0.0, +) / Double(group.count)
        let centerLng = group.map { $0.position.lng }.reduce(0.0, +) / Double(group.count)
        
        let clusterMarker = NMFMarker(position: NMGLatLng(lat: centerLat, lng: centerLng))
        
        // 클러스터 크기에 따른 스타일 설정
        switch group.count {
        case 0..<ClusterSize.small:
            clusterMarker.iconImage = NMFOverlayImage(name: "cluster_small")
            clusterMarker.width = 40
            clusterMarker.height = 40
        case ClusterSize.small..<ClusterSize.medium:
            clusterMarker.iconImage = NMFOverlayImage(name: "cluster_medium")
            clusterMarker.width = 50
            clusterMarker.height = 50
        default:
            clusterMarker.iconImage = NMFOverlayImage(name: "cluster_large")
            clusterMarker.width = 60
            clusterMarker.height = 60
        }
        
        clusterMarker.captionText = "\(group.count)"
        clusterMarker.captionTextSize = 14
        clusterMarker.captionColor = .white
        clusterMarker.captionHaloColor = .clear
        clusterMarker.mapView = mapView
        
        clusters.append(clusterMarker)
    }
    
    private func calculateDistance(_ pos1: NMGLatLng, _ pos2: NMGLatLng) -> Double {
        let location1 = CLLocation(latitude: pos1.lat, longitude: pos1.lng)
        let location2 = CLLocation(latitude: pos2.lat, longitude: pos2.lng)
        return location1.distance(from: location2)
    }
}

// MARK: - NMFMapViewCameraDelegate
extension MarkerManager: NMFMapViewCameraDelegate {
    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        updateClustering()
    }
}

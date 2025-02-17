//
//  AlertManagers.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/12/25.
//

import Foundation
import UserNotifications
import CoreLocation
import UIKit

class AlertManager: NSObject, CLLocationManagerDelegate {
    static let shared = AlertManager()
    private let locationManager = CLLocationManager()
    private let notificationDistance: Double = 300 // 300미터 반경
    private var stores: [LottoStore] = [] // 로또 판매점 데이터 저장용
    private var lastNotifiedStores: Set<String> = [] // 중복 알림 방지용
    
    private override init() {
        super.init()
        setupLocationManager()
        loadStoreData() // 초기화할 때 데이터 로드
    }
    
    private func loadStoreData() {
        // JSON 파일에서 데이터 로드
        if let path = Bundle.main.path(forResource: "LottoStores", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                stores = try decoder.decode([LottoStore].self, from: data)
                print("로또 판매점 데이터 로드 완료: \(stores.count)개")
            } catch {
                print("로또 판매점 데이터 로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 100 // 100미터 이상 움직였을 때만 업데이트
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // 백그라운드 위치 업데이트 설정 추가
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // 권한 요청을 'Always'로 변경
        locationManager.requestAlwaysAuthorization()
        
        // 위치 업데이트 시작 (앱 시작시 한 번만 호출되면 됨)
        locationManager.startUpdatingLocation()
    }
    
    // 위치가 업데이트될 때마다 호출되는 delegate 메서드
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         guard let currentLocation = locations.last else { return }
         
         // 디버깅용 프린트문 추가
         print("📍 위치 업데이트: lat: \(currentLocation.coordinate.latitude), lon: \(currentLocation.coordinate.longitude), 시간: \(Date())")
         
         // 현재 위치에서 근처 판매점 확인
         let nearbyStores = stores.filter { store in
             let storeLocation = CLLocation(
                 latitude: store.latitude,
                 longitude: store.longitude
             )
             return currentLocation.distance(from: storeLocation) <= notificationDistance
         }
         
         // 새로운 근처 판매점에 대해서만 알림 전송
         for store in nearbyStores {
             if !lastNotifiedStores.contains(store.name) {
                 sendNotification(for: store)
                 lastNotifiedStores.insert(store.name)
             }
         }
         
         // 범위를 벗어난 판매점은 다시 알림 가능하도록 설정
         lastNotifiedStores = Set(nearbyStores.map { $0.name })
     }
     
     private func sendNotification(for store: LottoStore) {
         let content = UNMutableNotificationContent()
         content.title = "근처에 로또 판매점이 있습니다!"
         content.body = "판매점: \(store.name)"
         content.sound = .default
         
         // 즉시 알림 전송
         let request = UNNotificationRequest(
             identifier: "storeNotification_\(store.name)",
             content: content,
             trigger: nil // 즉시 알림
         )
         
         UNUserNotificationCenter.current().add(request) { error in
             if let error = error {
                 print("알림 설정 실패: \(error.localizedDescription)")
             } else {
                 print("근처 판매점 알림 전송 완료: \(store.name)")
             }
         }
     }
 
    
    private func checkNearbyStores(completion: @escaping (LottoStore?) -> Void) {
        // 현재 위치 가져오기
        guard let currentLocation = locationManager.location else {
            completion(nil)
            return
        }
        
        // 가장 가까운 판매점 찾기
        let nearbyStore = stores.first { store in
            let storeLocation = CLLocation(
                latitude: store.latitude,
                longitude: store.longitude
            )
            let distance = currentLocation.distance(from: storeLocation)
            return distance <= notificationDistance
        }
        
        completion(nearbyStore)
    }
    
    // 알림 권한 요청
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("알림 권한이 허용되었습니다")
            } else {
                print("알림 권한이 거부되었습니다")
            }
        }
    }
}

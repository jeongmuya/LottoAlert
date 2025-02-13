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

class AlertManager {
    static let shared = AlertManager()
    private let locationManager = CLLocationManager()
    private let notificationDistance: Double = 500 // 500미터 반경
    private var stores: [LottoStore] = [] // 로또 판매점 데이터 저장용
    
    private init() {
        setupLocationManager()
        loadStoreData() // 초기화할 때 데이터 로드
        setupPeriodicLocationCheck()
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }
    
    // 로또 판매점 데이터 로드
    private func loadStoreData() {
        if let path = Bundle.main.path(forResource: "LottoStores", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                stores = try JSONDecoder().decode([LottoStore].self, from: data)
                print("로또 판매점 \(stores.count)개 로드 완료")
            } catch {
                print("로또 판매점 데이터 로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupPeriodicLocationCheck() {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        // 60초마다 위치 확인
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 60,  // 1분마다
            repeats: true
        )
        
        // 현재 위치 확인 및 근처 판매점 체크
        checkNearbyStores { nearbyStore in
            if let store = nearbyStore {
                // 근처에 판매점이 있을 경우 알림 내용 수정
                content.title = "근처에 로또 판매점이 있습니다!"
                content.body = """
                    판매점: \(store.name)
                    """
                
                // 판매점 이름을 식별자로 사용
                let request = UNNotificationRequest(
                    identifier: "storeNotification_\(store.name)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("알림 설정 실패: \(error.localizedDescription)")
                    } else {
                        print("근처 판매점 알림 설정 완료: \(store.name)")
                    }
                }
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

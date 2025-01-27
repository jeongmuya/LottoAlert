//
//  LottoAPIManger.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/20/25.
//

import Foundation
import CoreLocation

// 서버 에러 응답을 위한 구조체
struct ServerError: Codable {
    let code: Int
    let msg: String
}

class LottoAPIManager {
    static let shared = LottoAPIManager()
    
    // 누락된 API 관련 상수 추가
    private let baseURL = "https://api.odcloud.kr/api"
    private let path = "/15086355/v1/uddi:ef7ca84b-c2bc-404a-9743-85752073b61b"
    private let serviceKey = "S4Z3xung5wpu6TPz1bUEfRu8ln55RTZu4rwIDF61MPCFNDzcfOFIO7N2AFFgrCWLY2DooC%2B0Soo4pSsQ0U%2BIWg%3D%3D"
    
    private init() {}
    
    // 결과 타입 정의
    enum APIResult {
        case success([LottoStore])
        case failure(APIError)
    }
    
    // 에러 타입 정의
    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case noData
        case decodingError(Error)
        case serverError(Int, String)
        case invalidStatusCode(Int)
        case locationError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "잘못된 URL입니다."
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            case .invalidResponse:
                return "서버로부터 잘못된 응답을 받았습니다."
            case .noData:
                return "데이터를 받지 못했습니다."
            case .decodingError(let error):
                return "데이터 처리 오류: \(error.localizedDescription)"
            case .serverError(let code, _):
                return "서버 오류 (코드: \(code))"
            case .invalidStatusCode(let code):
                return "잘못된 응답 상태 코드: \(code)"
            case .locationError:
                return "위치 정보를 찾을 수 없습니다."
            }
        }
    }
    
    // 현재 위치 기반 로또 판매점 조회 메서드 추가
    func fetchNearbyLottoStores(latitude: Double,
                               longitude: Double,
                               radius: Int = 3000,
                               completion: @escaping (Result<[LottoStore], Error>) -> Void) {
        print("📡 검색 반경: \(radius)m")
        print("📡 현재 위치(\(latitude), \(longitude)) 기준으로 주변 판매점 검색 시작")
        
        let totalPages = 9 // 8394개 데이터를 1000개씩 나누면 약 9페이지
        var allStores: [LottoStore] = []
        let group = DispatchGroup()
        
        for page in 1...totalPages {
            group.enter()
            
            let urlString = "\(baseURL)\(path)?page=\(page)&perPage=1000&serviceKey=\(serviceKey)"
            guard let url = URL(string: urlString) else {
                group.leave()
                continue
            }
            
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                defer { group.leave() }
                
                if let error = error {
                    print("❌ 네트워크 에러: \(error.localizedDescription)")
                    completion(.failure(APIError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                print("📡 응답 상태 코드: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(APIError.invalidStatusCode(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 응답 데이터: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(LottoAPIResponse.self, from: data)
                    allStores.append(contentsOf: response.data)
                    print("✅ \(page)페이지 데이터 수신 완료 (누적: \(allStores.count)개)")
                } catch {
                    print("❌ \(page)페이지 디코딩 에러: \(error)")
                }
            }
            task.resume()
        }
        
        group.notify(queue: .main) { [weak self] in
            print("📍 전체 \(allStores.count)개의 판매점 데이터 수집 완료")
            
            // 지오코딩 및 거리 필터링 처리
            self?.processStoresData(allStores, 
                                  currentLatitude: latitude, 
                                  currentLongitude: longitude, 
                                  radius: radius, 
                                  completion: completion)
        }
    }
    
    private func processStoresData(_ stores: [LottoStore],
                                 currentLatitude: Double,
                                 currentLongitude: Double,
                                 radius: Int,
                                 completion: @escaping (Result<[LottoStore], Error>) -> Void) {
        let currentLocation = CLLocation(latitude: currentLatitude, longitude: currentLongitude)
        let geocoder = CLGeocoder()
        
        Task {
            do {
                // 1. 재시도 로직 추가
                var retryCount = 0
                var placemarks: [CLPlacemark]?
                
                while retryCount < 3 && placemarks == nil {
                    do {
                        placemarks = try await geocoder.reverseGeocodeLocation(currentLocation)
                        break
                    } catch {
                        retryCount += 1
                        if retryCount < 3 {
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
                        }
                    }
                }
                
                // 2. 에러 처리 개선
                guard let placemark = placemarks?.first else {
                    print("⚠️ 위치 정보를 찾을 수 없습니다. 기본 반경 검색으로 전환합니다.")
                    // 기본 반경 검색으로 전환
                    let nearbyStores = filterStoresByDistance(stores, 
                                                            currentLocation: currentLocation, 
                                                            radius: Double(radius))
                    completion(.success(nearbyStores))
                    return
                }
                
                // 3. 주소 기반으로 1차 필터링
                let administrativeArea = placemark.administrativeArea ?? "" // 시/도
                let locality = placemark.locality ?? "" // 시/군/구
                let subLocality = placemark.subLocality ?? "" // 동/읍/면
                
                print("🏠 현재 위치: \(administrativeArea) \(locality) \(subLocality)")
                
                // 4. 주소 기반 1차 필터링
                let filteredStores = stores.filter { store in
                    print("🔍 검사 중인 매장: \(store.name)")
                    print("📍 매장 주소: \(store.address)")
                    
                    // 시/도 처리 개선
                    let cityName = administrativeArea.replacingOccurrences(of: "광역시", with: "")
                                                   .replacingOccurrences(of: "특별시", with: "")
                                                   .replacingOccurrences(of: "시", with: "")
                    
                    // 구/군 처리 개선
                    let districtName = locality.replacingOccurrences(of: "시", with: "")
                                              .replacingOccurrences(of: "구", with: "")
                    
                    // 동/읍/면 처리 추가
                    let neighborhoodName = subLocality.replacingOccurrences(of: "동", with: "")
                                                     .replacingOccurrences(of: "읍", with: "")
                                                     .replacingOccurrences(of: "면", with: "")
                    
                    // 주소 매칭 조건 개선
                    let containsCity = store.address.contains(cityName)
                    let containsDistrict = !districtName.isEmpty && store.address.contains(districtName)
                    let containsNeighborhood = !neighborhoodName.isEmpty && store.address.contains(neighborhoodName)
                    
                    // 매칭 결과 로깅
                    if containsCity || containsDistrict || containsNeighborhood {
                        print("✅ 주소 매칭 성공: \(store.address)")
                        print("- 시/도 매칭: \(containsCity)")
                        print("- 구/군 매칭: \(containsDistrict)")
                        print("- 동/읍/면 매칭: \(containsNeighborhood)")
                    }
                    
                    // 시/도가 일치하고, 구/군이나 동/읍/면 중 하나라도 일치하면 포함
                    return containsCity && (containsDistrict || containsNeighborhood)
                }
                
                print("🏠 검색 기준:")
                print("- 시/도: \(administrativeArea)")
                print("- 시/군/구: \(locality)")
                print("- 동/읍/면: \(subLocality)")
                print("📍 1차 필터링 전 전체 판매점: \(stores.count)개")
                print("📍 1차 필터링 결과: \(filteredStores.count)개의 판매점")
                
                // 5. 지오코딩 및 거리 계산
                var processedStores: [LottoStore] = []
                let geocodingService = GeocodingService()
                
                for store in filteredStores {
                    do {
                        let coordinate = try await geocodingService.geocodeAddress(store.address)
                        // 새로운 store 인스턴스 생성
                        var updatedStore = store
                        updatedStore.latitude = String(coordinate.latitude)
                        updatedStore.longitude = String(coordinate.longitude)
                        
                        // 6. 거리 계산 및 반경 내 매장만 추가
                        let storeLocation = CLLocation(latitude: coordinate.latitude, 
                                                     longitude: coordinate.longitude)
                        let distance = currentLocation.distance(from: storeLocation)
                        
                        if distance <= Double(radius) {
                            processedStores.append(updatedStore)
                            print("✅ 반경 \(Int(distance))m 내 매장 발견: \(store.name) (\(store.address))")
                        }
                    } catch {
                        print("⚠️ 지오코딩 실패: \(store.name) - \(error.localizedDescription)")
                        continue
                    }
                }
                
                print("🎯 최종 필터링 완료: \(processedStores.count)개의 주변 판매점")
                
                // 7. 거리순으로 정렬
                let sortedStores = processedStores.sorted { store1, store2 in
                    guard let lat1 = Double(store1.latitude!),
                          let lng1 = Double(store1.longitude!),
                          let lat2 = Double(store2.latitude!),
                          let lng2 = Double(store2.longitude!) else {
                        return false
                    }
                    
                    let location1 = CLLocation(latitude: lat1, longitude: lng1)
                    let location2 = CLLocation(latitude: lat2, longitude: lng2)
                    
                    return currentLocation.distance(from: location1) < currentLocation.distance(from: location2)
                }
                
                // 필터링 단계에서 로그 추가
                sortedStores.forEach { store in
                    if let storeLat = Double(store.latitude ?? ""),
                       let storeLng = Double(store.longitude ?? "") {
                        let storeLocation = CLLocation(latitude: storeLat, longitude: storeLng)
                        let distance = currentLocation.distance(from: storeLocation)
                        print("📍 매장: \(store.name) - 거리: \(distance)m")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.success(sortedStores))
                }
                
            } catch {
                print("❌ 지오코딩 오류 발생: \(error.localizedDescription)")
                // 3. 폴백 처리
                let nearbyStores = filterStoresByDistance(stores, 
                                                        currentLocation: currentLocation, 
                                                        radius: Double(radius))
                completion(.success(nearbyStores))
            }
        }
    }
    
    // 거리 기반 필터링 헬퍼 메서드
    private func filterStoresByDistance(_ stores: [LottoStore], 
                                          currentLocation: CLLocation, 
                                          radius: Double) -> [LottoStore] {
        return stores.compactMap { store in
            guard let latString = store.latitude,
                  let lngString = store.longitude,
                  let lat = Double(latString),
                  let lng = Double(lngString) else {
                return nil
            }
            
            let storeLocation = CLLocation(latitude: lat, longitude: lng)
            let distance = currentLocation.distance(from: storeLocation)
            
            return distance <= radius ? store : nil
        }
    }
    
    // API 응답은 정상적으로 수신되나 파싱에 문제가 있을 수 있습니다
    func parseStoreData(_ data: Data) -> [LottoStore] {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(LottoAPIResponse.self, from: data)
            return response.data
        } catch {
            print("데이터 파싱 오류: \(error)")
            return []
        }
    }
}

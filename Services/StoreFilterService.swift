import Foundation
import CoreLocation

class StoreFilterService {
    static let shared = StoreFilterService()
    
    private init() {}
    
    // MARK: - 주소 기반 필터링
    func filterStoresByAddress(stores: [LottoStore], address: Address) -> [LottoStore] {
        print("🏠 검색 기준: \(address.sido) \(address.sigungu) \(address.dong)")
        
        return stores.filter { store in
            let storeAddress = store.address
            
            // 시/도 레벨 매칭 (광역시/도 처리)
            if !address.sido.isEmpty {
                let normalizedSido = normalizeSido(address.sido)
                if !storeAddress.contains(normalizedSido) { return false }
            }
            
            // 시/군/구 레벨 매칭
            if !address.sigungu.isEmpty {
                let normalizedSigungu = normalizeSigungu(address.sigungu, sido: address.sido)
                if !storeAddress.contains(normalizedSigungu) { return false }
            }
            
            // 동/읍/면 레벨 매칭
            if !address.dong.isEmpty {
                let normalizedDong = normalizeDong(address.dong)
                if !storeAddress.contains(normalizedDong) { return false }
            }
            
            return true
        }
    }
    
    // MARK: - 주소 정규화 헬퍼 메서드
    private func normalizeSido(_ sido: String) -> String {
        var normalized = sido
            .replacingOccurrences(of: "광역시", with: "")
            .replacingOccurrences(of: "특별시", with: "")
            .replacingOccurrences(of: "특별자치시", with: "")
            .replacingOccurrences(of: "특별자치도", with: "")
        
        // "도" 처리는 마지막에
        if normalized.hasSuffix("도") && normalized.count > 1 {
            normalized = String(normalized.dropLast())
        }
        
        return normalized.trimmingCharacters(in: .whitespaces)
    }
    
    private func normalizeSigungu(_ sigungu: String, sido: String) -> String {
        var normalized = sigungu
        
        // 시/도 부분 제거
        if !sido.isEmpty {
            normalized = normalized.replacingOccurrences(of: "\(sido) ", with: "")
        }
        
        // 일반적인 행정구역 접미사 처리
        normalized = normalized
            .replacingOccurrences(of: "시 ", with: "")
            .replacingOccurrences(of: "군 ", with: "")
            .replacingOccurrences(of: "구 ", with: "")
        
        return normalized.trimmingCharacters(in: .whitespaces)
    }
    
    private func normalizeDong(_ dong: String) -> String {
        return dong
            .replacingOccurrences(of: "동", with: "")
            .replacingOccurrences(of: "읍", with: "")
            .replacingOccurrences(of: "면", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - 거리 기반 필터링
    func filterStoresByDistance(stores: [LottoStore], 
                              currentLocation: CLLocation, 
                              radius: Double) -> [LottoStore] {
        print("📍 거리 기준: \(Int(radius))m")
        
        return stores.filter { store in
            guard let latString = store.latitude,
                  let lngString = store.longitude,
                  let lat = Double(latString),
                  let lng = Double(lngString) else {
                return false
            }
            
            let storeLocation = CLLocation(latitude: lat, longitude: lng)
            let distance = currentLocation.distance(from: storeLocation)
            
            return distance <= radius
        }
    }
    
    // MARK: - 검색어 기반 필터링
    func filterStoresByQuery(stores: [LottoStore], query: String) -> [LottoStore] {
        guard !query.isEmpty else { return stores }
        
        let searchTerms = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return stores.filter { store in
            let storeName = store.name.lowercased()
            let storeAddress = (store.address ?? "").lowercased()
            
            return searchTerms.allSatisfy { term in
                storeName.contains(term) || storeAddress.contains(term)
            }
        }
    }
    
    // MARK: - 통합 필터링
    func filterStores(stores: [LottoStore],
                     address: Address? = nil,
                     currentLocation: CLLocation? = nil,
                     radius: Double? = nil,
                     query: String? = nil) -> [LottoStore] {
        var filteredStores = stores
        print("\n📍 전체 판매점: \(stores.count)개")
        
        // 주소 기반 필터링
        if let address = address {
            filteredStores = filterStoresByAddress(stores: filteredStores, address: address)
            print("📍 주소 필터링 후: \(filteredStores.count)개")
        }
        
        // 거리 기반 필터링
        if let location = currentLocation, let radius = radius {
            filteredStores = filterStoresByDistance(stores: filteredStores, 
                                                  currentLocation: location, 
                                                  radius: radius)
            print("📍 거리 필터링 후: \(filteredStores.count)개")
        }
        
        // 검색어 기반 필터링
        if let query = query, !query.isEmpty {
            filteredStores = filterStoresByQuery(stores: filteredStores, query: query)
            print("📍 검색어 필터링 후: \(filteredStores.count)개")
        }
        
        return filteredStores
    }
} 

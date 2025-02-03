//
//  LottoStoreSearchManager.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/1/25.
//

import Foundation

class LottoStoreSearchManager {
    static let shared = LottoStoreSearchManager()
    private let userDefaults = UserDefaults.standard
    private let searchHistoryKey = "lottoStoreSearchHistory"
    
    private init() {}
    
    // 검색 기록 가져오기
    func getSearchHistory() -> [String] {
        return userDefaults.stringArray(forKey: searchHistoryKey) ?? []
    }
    
    // 검색어 저장
    func saveSearch(_ query: String) {
        var history = getSearchHistory()
        
        // 중복 검색어 제거
        history.removeAll { $0 == query }
        
        // 최근 검색어를 앞에 추가
        history.insert(query, at: 0)
        
        // 최대 20개까지만 저장
        if history.count > 20 {
            history = Array(history.prefix(20))
        }
        
        userDefaults.set(history, forKey: searchHistoryKey)
    }
    
    // 검색 기록 삭제
    func deleteSearchHistory(_ query: String) {
        var history = getSearchHistory()
        history.removeAll { $0 == query }
        userDefaults.set(history, forKey: searchHistoryKey)
    }
    
    // 전체 검색 기록 삭제
    func clearAllSearchHistory() {
        userDefaults.removeObject(forKey: searchHistoryKey)
    }
    
    // 검색 성능 최적화
    func searchStores(_ query: String, in stores: [LottoStore]) -> [LottoStore] {
        let searchTerms = query.lowercased().split(separator: " ")
        
        return stores.filter { store in
            let storeName = store.name.lowercased()
            let storeAddress = store.address.lowercased()
            
            return searchTerms.allSatisfy { term in
                storeName.contains(term) || storeAddress.contains(term)
            }
        }
    }
}


////
////  LottoStoreSearchManager.swift
////  LottoAlert
////
////  Created by YangJeongMu on 2/1/25.
////
//
//import Foundation
//
//class LottoStoreSearchManager {
//    static let shared = LottoStoreSearchManager()
//    private let userDefaults = UserDefaults.standard
//    private let searchHistoryKey = "lottoStoreSearchHistory"
//    
//    private init() {}
//    
//    // 검색 기록 가져오기
//    func getSearchHistory() -> [String] {
//        return userDefaults.stringArray(forKey: searchHistoryKey) ?? []
//    }
//    
//    // 검색어 저장
//    func saveSearch(_ query: String) {
//        var history = getSearchHistory()
//        
//        // 중복 검색어 제거
//        history.removeAll { $0 == query }
//        
//        // 최근 검색어를 앞에 추가
//        history.insert(query, at: 0)
//        
//        // 최대 20개까지만 저장
//        if history.count > 20 {
//            history = Array(history.prefix(20))
//        }
//        
//        userDefaults.set(history, forKey: searchHistoryKey)
//    }
//}

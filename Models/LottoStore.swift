//
//  LottoStore.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/20/25.
//

import Foundation

struct APIError: Codable {
    let code: Int
    let msg: String
}

struct LottoAPIResponse: Codable {
    let page: Int
    let perPage: Int
    let totalCount: Int
    let currentCount: Int
    let matchCount: Int
    let data: [LottoStore]
}

struct LottoStore: Codable {
    let number: Int
    let name: String
    let roadAddress: String
    let address: String
    var latitude: String?
    var longitude: String?
    
    var id: String? {
        return String(number)
    }
    
    enum CodingKeys: String, CodingKey {
        case number = "번호"
        case name = "상호"
        case roadAddress = "도로명주소"
        case address = "지번주소"
        case latitude = "위도"
        case longitude = "경도"
    }
}

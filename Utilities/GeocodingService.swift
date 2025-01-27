//
//  GeocodingService.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/21/25.
//


import Foundation
import CoreLocation

// MARK: - Models
fileprivate struct GeocodingResponse: Codable {
    let status: String
    let meta: Meta
    let addresses: [Address]
    let errorMessage: String?
}

fileprivate struct Meta: Codable {
    let totalCount: Int
    let page: Int
    let count: Int
}

fileprivate struct Address: Codable {
    let roadAddress: String
    let jibunAddress: String
    let englishAddress: String
    let x: String  // 경도
    let y: String  // 위도
    let distance: Double
}

// 외부에서도 사용할 수 있도록 public으로 선언 (한 번만 선언)
public enum GeocodingError: Error {
    case invalidURL
    case invalidResponse
    case noResults
    case invalidAddress
    case apiError(String)
}

class GeocodingService {
    private let baseURL = "https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode"
    private let clientId: String
    private let clientSecret: String
    
    init() {
        // Info.plist에서 API 키 읽기
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let apiKeys = dict["NaverAPIKeys"] as? [String: String],
              let clientId = apiKeys["ClientID"],
              let clientSecret = apiKeys["ClientSecret"] else {
            fatalError("네이버 API 키 설정이 필요합니다.")
        }
        
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "\(baseURL)?query=\(encodedAddress)"
        
        guard let url = URL(string: urlString) else {
            throw GeocodingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        // 저장된 API 키 사용
        request.setValue(clientId, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.setValue(clientSecret, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
        
        print("🔍 지오코딩 요청: \(address)")
        // API 키는 보안을 위해 로그에 출력하지 않음
        print("🌐 URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 응답 상태 코드: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 응답 데이터: \(responseString)")
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw GeocodingError.invalidResponse
            }
            
            let result = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            
            guard let firstAddress = result.addresses.first else {
                throw GeocodingError.noResults
            }
            
            guard let latitude = Double(firstAddress.y),
                  let longitude = Double(firstAddress.x) else {
                throw GeocodingError.invalidResponse
            }
            
            print("✅ 지오코딩 성공: \(address) → (\(latitude), \(longitude))")
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } catch {
            print("❌ 지오코딩 실패: \(error.localizedDescription)")
            throw error
        }
    }
}

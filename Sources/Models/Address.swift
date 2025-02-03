struct Address {
    var sido: String
    var sigungu: String
    var dong: String
    
    // 정규화된 주소 반환
    var formattedAddress: String {
        var components: [String] = []
        if !sido.isEmpty { components.append(sido) }
        
        // 시/군/구에서 시/도 중복 제거
        if !sigungu.isEmpty {
            let cleanedSigungu = sigungu.replacingOccurrences(of: "\(sido) ", with: "")
            components.append(cleanedSigungu)
        }
        
        if !dong.isEmpty { components.append(dong) }
        return components.joined(separator: " ")
    }
}
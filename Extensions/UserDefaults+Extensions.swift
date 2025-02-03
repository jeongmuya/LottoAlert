import Foundation

extension UserDefaults {
    private static let recommendationsKey = "lottoRecommendations"
    
    func saveRecommendation(_ recommendation: LottoRecommendation) {
        var recommendations = loadRecommendations()
        recommendations.insert(recommendation, at: 0)  // 최신 항목을 맨 위에 추가
        
        // 최대 50개까지만 저장
        if recommendations.count > 50 {
            recommendations = Array(recommendations.prefix(50))
        }
        
        if let encoded = try? JSONEncoder().encode(recommendations) {
            self.set(encoded, forKey: UserDefaults.recommendationsKey)
        }
    }
    
    func loadRecommendations() -> [LottoRecommendation] {
        guard let data = self.data(forKey: UserDefaults.recommendationsKey),
              let recommendations = try? JSONDecoder().decode([LottoRecommendation].self, from: data) else {
            return []
        }
        return recommendations
    }
    
    func clearRecommendations() {
        self.removeObject(forKey: UserDefaults.recommendationsKey)
    }
} 
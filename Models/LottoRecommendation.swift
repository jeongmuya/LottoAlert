import Foundation

struct LottoRecommendation: Codable {
    let id: String
    let numbers: [Int]
    let storeName: String
    let date: Date
    
    init(id: String = UUID().uuidString, numbers: [Int], storeName: String, date: Date = Date()) {
        self.id = id
        self.numbers = numbers
        self.storeName = storeName
        self.date = date
    }
} 
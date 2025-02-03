import Foundation

struct LottoRecommendation: Codable {
    let id: String
    var numbers: [Int]
    let storeName: String
    var date: Date
    var specialNumbers: [Int]  // 볼드체, 황금색으로 표시될 번호들
    
    init(id: String = UUID().uuidString, 
         numbers: [Int], 
         storeName: String, 
         date: Date = Date(),
         specialNumbers: [Int] = []) {
        self.id = id
        self.numbers = numbers
        self.storeName = storeName
        self.date = date
        self.specialNumbers = specialNumbers
    }
} 
//
//  Annotations.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/12/25.
//

// Annotations.swift

import UIKit
import MapKit

class CustomAnnotation: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    @objc dynamic var coordinate: CLLocationCoordinate2D

    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}



final class AnnotationManager {
    static let shared = AnnotationManager()
    private init() {}
    
    // 데이터를 저장할 프로퍼티
    private var lottoStores: [LottoStore] = []
    
    // JSON 파일에서 데이터 로드
    func loadStoresFromJSON() {
        if let path = Bundle.main.path(forResource: "LottoStores", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            lottoStores = (try? JSONDecoder().decode([LottoStore].self, from: data)) ?? []
        }
    }
    
    func loadStores() -> [CustomAnnotation] {
        return lottoStores.map { store in
            CustomAnnotation(
                title: store.name,
                subtitle: "",
                coordinate: CLLocationCoordinate2D(
                    latitude: store.latitude,
                    longitude: store.longitude
                )
            )
        }
    }
}

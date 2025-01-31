import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LottoStore")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 로드 실패: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // 판매점 저장
    func saveStores(_ stores: [LottoStore]) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // 기존 데이터 삭제
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LottoStore")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try self.context.execute(deleteRequest)
                
                // 새로운 데이터 저장
                for store in stores {
                    let storeEntity = NSEntityDescription.insertNewObject(forEntityName: "LottoStore", into: self.context)
                    storeEntity.setValue(String(store.number), forKey: "id")  // Int를 String으로 변환
                    storeEntity.setValue(store.name, forKey: "name")
                    storeEntity.setValue(store.address, forKey: "address")
                    storeEntity.setValue(store.latitude ?? "", forKey: "latitude")
                    storeEntity.setValue(store.longitude ?? "", forKey: "longitude")
                    storeEntity.setValue(store.number, forKey: "number")
                    storeEntity.setValue(store.roadAddress ?? "", forKey: "roadAddress")
                    storeEntity.setValue(Date(), forKey: "lastUpdated")
                }
                
                try self.context.save()
                print("✅ 판매점 데이터 저장 완료")
            } catch {
                print("❌ CoreData 저장 실패: \(error)")
            }
        }
    }
    
    // 저장된 판매점 조회
    func fetchStores() -> [LottoStore] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "LottoStore")
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { entity -> LottoStore? in
                guard let idString = entity.value(forKey: "id") as? String,
                      let name = entity.value(forKey: "name") as? String,
                      let address = entity.value(forKey: "address") as? String,
                      let number = Int(idString) else {  // String을 Int로 변환
                    return nil
                }
                
                return LottoStore(
                    number: number,  // Int 값 사용
                    name: name,
                    roadAddress: entity.value(forKey: "roadAddress") as? String ?? "",
                    address: address,
                    latitude: entity.value(forKey: "latitude") as? String,
                    longitude: entity.value(forKey: "longitude") as? String
                )
            }
        } catch {
            print("❌ CoreData 조회 실패: \(error)")
            return []
        }
    }
    
    // 마지막 업데이트 시간 확인
    func getLastUpdateTime() -> Date? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "LottoStore")
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.value(forKey: "lastUpdated") as? Date
        } catch {
            return nil
        }
    }
} 
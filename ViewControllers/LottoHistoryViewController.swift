import UIKit
import SnapKit

class LottoHistoryViewController: UIViewController {
    
    // MARK: - Properties
    private var groupedRecommendations: [(storeName: String, recommendations: [LottoRecommendation])] = []
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(LottoNumberCell.self, forCellReuseIdentifier: LottoNumberCell.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .white
        return table
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 추천받은 번호가 없습니다"
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecommendations()
        
        // 탭바 배경색 유지
        tabBarController?.tabBar.backgroundColor = .white
        tabBarController?.tabBar.isTranslucent = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecommendations()
        tableView.reloadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "추천 번호 목록"
        view.backgroundColor = .white  // 뷰 컨트롤러 배경색 설정
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // 셀 재사용 최적화
        tableView.prefetchDataSource = self
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    // MARK: - Data Loading
    private func loadRecommendations() {
        if let data = UserDefaults.standard.data(forKey: "lottoRecommendations"),
           let recommendations = try? JSONDecoder().decode([LottoRecommendation].self, from: data) {
            // 판매점별로 그룹화
            let grouped = Dictionary(grouping: recommendations) { $0.storeName }
            // 판매점 이름으로 정렬하고 각 그룹 내에서는 날짜순 정렬
            groupedRecommendations = grouped.map { (storeName: $0.key, recommendations: $0.value.sorted { $0.date > $1.date }) }
                .sorted { $0.storeName < $1.storeName }
        } else {
            groupedRecommendations = []
        }
        
        emptyLabel.isHidden = !groupedRecommendations.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension LottoHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedRecommendations.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedRecommendations[section].recommendations.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groupedRecommendations[section].storeName
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LottoNumberCell.identifier, for: indexPath) as? LottoNumberCell else {
            return UITableViewCell()
        }
        
        let recommendation = groupedRecommendations[indexPath.section].recommendations[indexPath.row]
        cell.configure(with: recommendation)
        return cell
    }
    
    // 섹션 헤더 스타일 설정
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        let label = UILabel()
        label.text = groupedRecommendations[section].storeName
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        
        headerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    // 스와이프 액션 추가
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 삭제 액션
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] (_, _, completion) in
            self?.deleteRecommendation(at: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        // 새 번호 추천 액션
        let newNumbersAction = UIContextualAction(style: .normal, title: "새 번호") { [weak self] (_, _, completion) in
            self?.generateNewNumbers(at: indexPath)
            completion(true)
        }
        newNumbersAction.backgroundColor = .systemBlue
        
        // 액션 배열로 configuration 생성
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, newNumbersAction])
        configuration.performsFirstActionWithFullSwipe = false
        
        return configuration
    }
    
    // 삭제 기능 구현
    private func deleteRecommendation(at indexPath: IndexPath) {
        // 현재 섹션의 추천 목록에서 해당 항목 제거
        var recommendations = groupedRecommendations[indexPath.section].recommendations
        recommendations.remove(at: indexPath.row)
        
        // 해당 섹션의 모든 추천이 삭제되었다면 섹션도 제거
        if recommendations.isEmpty {
            groupedRecommendations.remove(at: indexPath.section)
        } else {
            groupedRecommendations[indexPath.section].recommendations = recommendations
        }
        
        // UserDefaults 업데이트
        let allRecommendations = groupedRecommendations.flatMap { $0.recommendations }
        if let encoded = try? JSONEncoder().encode(allRecommendations) {
            UserDefaults.standard.set(encoded, forKey: "lottoRecommendations")
        }
        
        // 테이블뷰 업데이트
        if recommendations.isEmpty {
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        // 모든 추천이 삭제되었다면 빈 화면 표시
        emptyLabel.isHidden = !groupedRecommendations.isEmpty
    }
    
    // 새 번호 생성 기능 구현
    private func generateNewNumbers(at indexPath: IndexPath) {
        var recommendation = groupedRecommendations[indexPath.section].recommendations[indexPath.row]
        
        // 새로운 번호 생성 (70% 확률로 특별 번호 지정)
        var numbers = Set<Int>()
        while numbers.count < 6 {
            numbers.insert(Int.random(in: 1...45))
        }
        let sortedNumbers = Array(numbers).sorted()
        
        // 70% 확률로 모든 번호를 특별 번호로 지정
        let shouldGenerateSpecial = Double.random(in: 0...1) < 0.7
        let specialNumbers = shouldGenerateSpecial ? sortedNumbers : []
        
        // 새로운 추천 번호로 업데이트
        recommendation.numbers = sortedNumbers
        recommendation.specialNumbers = specialNumbers
        recommendation.date = Date()  // 현재 시간으로 업데이트
        
        // 데이터 업데이트
        groupedRecommendations[indexPath.section].recommendations[indexPath.row] = recommendation
        
        // UserDefaults 업데이트
        let allRecommendations = groupedRecommendations.flatMap { $0.recommendations }
        if let encoded = try? JSONEncoder().encode(allRecommendations) {
            UserDefaults.standard.set(encoded, forKey: "lottoRecommendations")
        }
        
        // 테이블뷰 업데이트
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// UITableViewDataSourcePrefetching 구현
extension LottoHistoryViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // 미리 셀 준비
        for indexPath in indexPaths {
            if indexPath.section < groupedRecommendations.count,
               indexPath.row < groupedRecommendations[indexPath.section].recommendations.count {
                let _ = tableView.dequeueReusableCell(withIdentifier: LottoNumberCell.identifier) as? LottoNumberCell
            }
        }
    }
} 
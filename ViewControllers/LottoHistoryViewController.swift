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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecommendations()
        tableView.reloadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "추천 번호 목록"
        view.backgroundColor = .white
        
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
} 
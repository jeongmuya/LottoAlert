import UIKit

protocol LottoStoreSearchViewControllerDelegate: AnyObject {
    func searchViewController(_ controller: LottoStoreSearchViewController, didSelectStore store: LottoStore)
}

class LottoStoreSearchViewController: UIViewController {
    // MARK: - Properties
    private let searchManager = LottoStoreSearchManager.shared
    private var stores: [LottoStore] = []
    private var filteredStores: [LottoStore] = []
    private var searchHistory: [String] = []
    private var searchWorkItem: DispatchWorkItem?  // 검색 작업 관리용
    weak var delegate: LottoStoreSearchViewControllerDelegate?
    
    // MARK: - UI Components
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "판매점 이름 또는 주소로 검색"
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return table
    }()
    
    private let clearHistoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("검색기록 전체삭제", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        loadSearchHistory()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        searchBar.backgroundColor = .white
        searchBar.barTintColor = .white
        searchBar.tintColor = .black
        
        tableView.backgroundColor = .white
        
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(clearHistoryButton)
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        clearHistoryButton.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(30)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(clearHistoryButton.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        clearHistoryButton.addTarget(self, action: #selector(clearHistoryButtonTapped), for: .touchUpInside)
    }
    
    private func setupDelegates() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Data
    func configure(with stores: [LottoStore]) {
        self.stores = stores
    }
    
    private func loadSearchHistory() {
        searchHistory = searchManager.getSearchHistory()
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func clearHistoryButtonTapped() {
        let alert = UIAlertController(
            title: "검색기록 삭제",
            message: "모든 검색기록을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.searchManager.clearAllSearchHistory()
            self?.loadSearchHistory()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension LottoStoreSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 이전 검색 작업 취소
        searchWorkItem?.cancel()
        
        // 빈 검색어 처리
        if searchText.isEmpty {
            filteredStores = []
            loadSearchHistory()
            return
        }
        
        // 새로운 검색 작업 생성
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // 백그라운드에서 검색 수행
            let filtered = self.searchManager.searchStores(searchText, in: self.stores)
            
            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                self.filteredStores = filtered
                self.tableView.reloadData()
            }
        }
        
        self.searchWorkItem = workItem
        
        // 0.3초 딜레이 후 검색 실행
        DispatchQueue.global(qos: .userInitiated).asyncAfter(
            deadline: .now() + 0.3,
            execute: workItem
        )
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchManager.saveSearch(query)
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension LottoStoreSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchBar.text?.isEmpty == false ? filteredStores.count : searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .white
        
        if searchBar.text?.isEmpty == false {
            let store = filteredStores[indexPath.row]
            cell.textLabel?.text = "\(store.name) - \(store.address)"
            cell.textLabel?.textColor = .black
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = searchHistory[indexPath.row]
            cell.textLabel?.textColor = .black
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if searchBar.text?.isEmpty == false {
            let store = filteredStores[indexPath.row]
            delegate?.searchViewController(self, didSelectStore: store)
            dismiss(animated: true)
        } else {
            let query = searchHistory[indexPath.row]
            searchBar.text = query
            filteredStores = searchManager.searchStores(query, in: stores)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard searchBar.text?.isEmpty == true else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            guard let self = self else { return }
            let query = self.searchHistory[indexPath.row]
            self.searchManager.deleteSearchHistory(query)
            self.loadSearchHistory()
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
} 
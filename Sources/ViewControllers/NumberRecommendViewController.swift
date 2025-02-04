import UIKit
import SnapKit
import Foundation

class NumberRecommendViewController: UIViewController {
    
    // MARK: - Properties
    
    // 최상단 "번호 추천"
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "번호 추천"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    // 상단 컨테이너 뷰 - 메달, 주차, 날짜, 당첨금액을 포함하는 박스
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hue: 0.1194, saturation: 0.18, brightness: 1, alpha: 1.0)
        view.layer.cornerRadius = 16
        return view
    }()
    
    // 메달 이미지
    private let medalImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "medal")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // 주차 표시 라벨
    private let weekLabel: UILabel = {
        let label = UILabel()
        label.text = "2월 1째주"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    // 날짜 범위 라벨
    private let dateRangeLabel: UILabel = {
        let label = UILabel()
        label.text = "2025년 2월 2일 - 2025년 2월 8일"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    // 당첨금액 라벨
    private let prizeAmountLabel: UILabel = {
        let label = UILabel()
        label.text = "23,000,000,000원"
        label.font = .h4
        label.textColor = .black
        return label
    }()
    
    // 남은 시간 표시 라벨
    private let remainingTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "⏱ 추첨까지  일  시  분  초 남음"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    // 행운 메시지 라벨
    private let luckyMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "당신이 이번주 행운의 주인공입니다."
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    // 번호 받기 버튼
    private let getNumberButton: UIButton = {
        let button = UIButton()
        button.setTitle("황금 번호 받기", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .heavy)
        button.backgroundColor = UIColor(hue: 0.1083, saturation: 0.61, brightness: 1, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(getNumberButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // 번호 표시 테이블뷰
    private let numberTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(NumberCell.self, forCellReuseIdentifier: "NumberCell")
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.97, alpha: 1.0)
        tableView.layer.cornerRadius = 16
        return tableView
    }()
    
    // 타이머 객체
    private var timer: Timer?

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(titleLabel)
        view.addSubview(containerView)
        
        [medalImageView, weekLabel, dateRangeLabel, prizeAmountLabel].forEach {
              containerView.addSubview($0)
          }
        
        [remainingTimeLabel, luckyMessageLabel, getNumberButton, numberTableView].forEach {
            view.addSubview($0)
            
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // 타이틀 라벨 제약조건
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-10)
            make.leading.equalToSuperview().offset(20)
        }
        
        // 컨테이너 뷰 제약조건
        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }
        
        // 메달 이미지 제약조건
        medalImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.width.height.equalTo(100)
        }
        
        // 주차 라벨 제약조건
        weekLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(medalImageView.snp.trailing).offset(12)
        }
        
        // 날짜 범위 라벨 제약조건
        dateRangeLabel.snp.makeConstraints { make in
            make.top.equalTo(weekLabel.snp.bottom).offset(4)
            make.leading.equalTo(weekLabel)
        }
        
        // 당첨금액 라벨 제약조건
        prizeAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(dateRangeLabel.snp.bottom).offset(8)
            make.leading.equalTo(weekLabel)
        }
        
        // 남은 시간 라벨 제약조건
        remainingTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        // 행운 메세지 라벨 제약조건
        luckyMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(remainingTimeLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(20)
        }
        
        // 번호 받기 버튼 제약조건
        getNumberButton.snp.makeConstraints { make in
            make.top.equalTo(luckyMessageLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        // 번호 표시 테이블뷰 제약조건
        numberTableView.snp.makeConstraints{ make in
            make.top.equalTo(getNumberButton.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(300)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
        
    }
    
    private func setupTableView() {
        numberTableView.delegate = self
        numberTableView.dataSource = self
    }
    
    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTimer() {
        // 타이머 업데이트 로직
        // 다음 토요일 20:35:00 시간 계산
        let nextDrawDate = getNextLotteryDrawDate()
        // 현재 시간과의 차이 계산
        let timeInterval = nextDrawDate.timeIntervalSinceNow
        // 남은 시간 계산 및 표시
        if timeInterval > 0 {
            // 남은 시간을 일, 시, 분, 초로 변환
            let days = Int(timeInterval) / 86400 // 86400 = 24 * 60 * 60
            let hours = Int(timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600
            let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            
            // 레이블 텍스트 업데이트
            remainingTimeLabel.text = "⏱ 추첨까지 \(days)일 \(hours)시 \(minutes)분 \(seconds)초 남음"
        } else {
            // 추첨 시간이 지난 경우
            remainingTimeLabel.text = "⏱ 다음 추첨을 기다려주세요"
            timer?.invalidate()
            timer = nil
            startTimer() // 다음 회차를 위해 타이머 재시작
        }
    }
    // 다음 로또 추첨 시간 계산 함수
    private func getNextLotteryDrawDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 현재 주의 토요일 20:35:00 계산
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 7
        components.hour = 20
        components.minute = 35
        components.second = 0
        
        guard let nextDrawDate = calendar.date(from: components) else { return Date() }
        
        // 현재 시간이 이번주 토요일 추첨시간 이후라면 다음 주 토요일로 설정
        if nextDrawDate <= now {
            return calendar.date(byAdding: .day, value: 7, to: nextDrawDate) ?? Date()
        }
        return nextDrawDate
    }
    
    // MARK: - Actions
      @objc private func getNumberButtonTapped() {
          // 번호 받기 버튼 탭 처리
      }

}

// MARK: - TableView DataSource & Delegate
extension NumberRecommendViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // 각 행의 높이
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5 // 5줄의 번호
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NumberCell",
                                                       for: indexPath) as? NumberCell else {
            return UITableViewCell()
        }
        cell.configure(with: [01, 11, 22, 31, 41, 45]) // 예시 번호
        return cell
    }
}

// MARK: - NumberCell
class NumberCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numbers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberItemCell", for: indexPath) as? NumberItemCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: numbers[indexPath.item])
              return cell
    }
    
    // 6개의 번호를 표시할 CollectionView
    private let numberCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 40, height: 40)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10) // 좌우 여백
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .blue
        cv.register(NumberItemCell.self, forCellWithReuseIdentifier: "NumberItemCell")
        return cv
    }()
    
    private var numbers: [Int] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.layer.masksToBounds = true
        contentView.addSubview(numberCollectionView)
        numberCollectionView.delegate = self
        numberCollectionView.dataSource = self
        
        numberCollectionView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()  // 수직 중앙 정렬
            make.centerX.equalToSuperview()  // 수평 중앙 정렬
            make.width.equalTo(contentView).multipliedBy(0.9)
            make.height.equalTo(70)
        }
    }
    
    func configure(with numbers: [Int]) {
        self.numbers = numbers
        numberCollectionView.reloadData()
    }
}
// MARK: - extension NumberCell
extension NumberCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 40) // 각 번호 셀의 크기
    }
}




// MARK: - NumberItemCell
class NumberItemCell: UICollectionViewCell {
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private var number: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = getBackgroundColor(for: number)
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        
        contentView.addSubview(numberLabel)
        
        
        numberLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    private func getBackgroundColor(for number: Int) -> UIColor {
        switch number {
        case 1...10: return .systemYellow.withAlphaComponent(0.9)
        case 11...20: return .systemBlue.withAlphaComponent(0.9)
        case 21...30: return .systemRed.withAlphaComponent(0.9)
        case 31...40: return .systemGray.withAlphaComponent(0.9)
        default: return .systemGray
        }
    }
    func configure(with number: Int) {
        self.number = number
        contentView.backgroundColor = getBackgroundColor(for: number)
        // 한 자리 숫자일 경우 앞에 0을 붙임
        numberLabel.text = String(format: "%02d", number)
    }
}

//extension NumberCell: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        // 셀 높이에 비례해서 공 크기 계산
//        let cellHeight = contentView.bounds.height - 16 // 여백 제외
//        let ballSize = cellHeight * 0.7 // 셀 높이의 70% 크기로 설정
//        
//        return CGSize(width: ballSize, height: ballSize)
//    }
//}

import UIKit
import SnapKit
import Foundation
import Lottie

class NumberRecommendViewController: UIViewController {
    
    // MARK: - Properties

    // Lottie animation 프로퍼티
    private let fireworksAnimationView: FireworksAnimationView = {
        let animationView = FireworksAnimationView(frame: UIScreen.main.bounds)  // 전체 화면 크기로 초기화
        animationView.isUserInteractionEnabled = false  // 터치 이벤트 방지
        animationView.backgroundColor = .clear
        return animationView
    }()
    
    
    // 최상단 "번호 추천" 라벨
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
        label.text = "로또 당첨이 되려면 무엇보다 일단 구매를 해야한다."
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    // 번호 받기 버튼
    private let getNumberButton: UIButton = {
        let button = UIButton(type: .system)
        
        
        // 기본 설정
        button.setTitle("당첨 번호 받기", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .heavy)
        
        // 상태별 배경색 설정
        let normalColor = UIColor(red: 245/255, green: 220/255, blue: 37/255, alpha: 1.0)
        let highlightedColor = UIColor(red: 245/255, green: 220/255, blue: 37/255, alpha: 0.8)
        let pressedColor = UIColor(red: 245/255, green: 220/255, blue: 37/255, alpha: 0.6)
        
//        button.setBackgroundColor(normalColor, for: .normal)
//        button.setBackgroundColor(highlightedColor, for: .highlighted)
        
        // 모서리 둥글게
        button.layer.cornerRadius = 12
        
        // 기본 배경색 제거 (그라데이션이 보이도록)
        button.backgroundColor = .clear
        
        // 외부 그림자
          button.layer.shadowColor = UIColor.black.cgColor
          button.layer.shadowOffset = CGSize(width: 0, height: 2)
          button.layer.shadowRadius = 4
          button.layer.shadowOpacity = 0.2
          
          // 테두리
          button.layer.borderWidth = 0.5
          button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
          
          // 그라데이션 레이어
          let gradientLayer = CAGradientLayer()
          gradientLayer.name = "buttonGradient"
          gradientLayer.cornerRadius = 12
          gradientLayer.type = .radial
          
          // 색상 설정 - 입체감을 위한 색상 조정
          let baseColor = UIColor(red: 245/255, green: 220/255, blue: 37/255, alpha: 1.0)
          let orangeColor = UIColor(red: 245/255, green: 184/255, blue: 0/255, alpha: 1.0)
          
          let lightColor = baseColor.withAlphaComponent(1.0)
          let midColor = baseColor.withAlphaComponent(0.9)
          let darkColor = orangeColor.withAlphaComponent(0.8)
          
          gradientLayer.colors = [
              lightColor.cgColor,
              midColor.cgColor,
              darkColor.cgColor
          ]
          
          // 그라데이션 위치 - 더 자연스러운 분포
          gradientLayer.locations = [0.2, 0.5, 1.0]
          
          gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
          gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
          
          button.layer.insertSublayer(gradientLayer, at: 0)
        
 
//        button.clipsToBounds = true
        
        // 터치 이벤트 추가
        button.addTarget(self, action: #selector(getNumberButtonTapped), for: .touchUpInside)
        button.addTarget(self, action: #selector(touchDown), for: .touchDown)
        button.addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside])
        
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
    
    
    
    // 생성된 로또 번호들을 저장할 배열 추가
    private var generatedNumbers: [[Int]] = []
    
    // 버튼이 눌렸는지 상태를 추적
    private var isNumbersGenerated: Bool = false
    
    // MARK: - Actions
    @objc private func getNumberButtonTapped() {
        
        // 오렌지 행 카운트 리셋
              NumberCell.orangeRowCount = 0
        
        // 5세트의 로또 번호 생성
        generatedNumbers = (0..<5).map { _ in
            generateLottoNumbers()
        }
        
        // 테이블뷰 새로고침
        numberTableView.reloadData()
        
        // 버튼 텍스트 변경
        if  !isNumbersGenerated {
            getNumberButton.setTitle("당첨 번호 다시 받기", for: .normal)
            isNumbersGenerated = true
        }
        
        
        // 버튼 눌렀을 때 진동 효과
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    // 터치 업 효과
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            // 버튼을 원래 크기와 위치로
            self.getNumberButton.transform = .identity
            // 그림자 효과 복원
            self.getNumberButton.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.getNumberButton.layer.shadowRadius = 5
        }
    }
    
    // 터치 다운 효과
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            // 버튼을 약간 작게 만들고 아래로 이동
            self.getNumberButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            // 그림자 효과 줄이기
            self.getNumberButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.getNumberButton.layer.shadowRadius = 3
        }
    }
    
    
    // 로또 번호 생성 메서드
    private func generateLottoNumbers() -> [Int] {
        var numbers = Set<Int>()
        
        // 1 부터 45까지의 숫자 중 6개를 무작위로 선택
        while numbers.count < 6 {
            let radomNumber = Int.random(in: 1...45)
            numbers.insert(radomNumber)
        }
        
        // 오름차순으로 정렬하여 반환
        return Array(numbers).sorted()
    }
    
    
    // MARK: - Lotto API Model
    struct LottoResult: Codable {
        let returnValue: String
        let drwNoDate: String
        let firstWinamnt: Int
        let firstPrzwnerCo: Int
    }
    
    // MARK: - fetchLatestLottoPrize
    private func fetchLatestLottoPrize() {
        // 이번 주 토요일 날짜 구하기
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 7 // 토요일
        components.hour = 20
        components.minute = 35
        
        guard let nextSaturday = calendar.date(from: components) else { return }
        
        // 이번 주 토요일이 지나지 않았다면 지난 주 당첨 결과를,
        // 지났다면 이번 주 당첨 결과를 가져옴
        let targetDate = today > nextSaturday ? nextSaturday : calendar.date(byAdding: .day, value: -7, to: nextSaturday)!
        
        // 회차 번호 계산 (2002년 12월 7일 1회차 기준)
        let firstDrawDate = "2002-12-07"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = dateFormatter.date(from: firstDrawDate) else { return }
        
        let weeks = calendar.dateComponents([.weekOfYear], from: startDate, to: targetDate).weekOfYear ?? 0
        let drawNo = weeks + 1
        
        let urlString = "https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo=\(drawNo)"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data,
                  let result = try? JSONDecoder().decode(LottoResult.self, from: data),
                  result.returnValue == "success" else {
                return
            }
            
            DispatchQueue.main.async {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                if let formattedAmount = numberFormatter.string(from: NSNumber(value: result.firstWinamnt)) {
                    self?.prizeAmountLabel.text = "\(formattedAmount)원"
                }
            }
        }
        
        task.resume()
    }
    
    // 타이머 객체
    //    private var timer: Timer?
    
    private var timer: DispatchSourceTimer?
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        startTimer()
        updateDateLabels()
        fetchLatestLottoPrize() // 당첨금액 api로 가져오기
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 그라데이션 레이어 프레임 업데이트
        if let gradientLayer = getNumberButton.layer.sublayers?.first(where: { $0.name == "buttonGradient" }) as? CAGradientLayer {
            gradientLayer.frame = getNumberButton.bounds
        }
    }


    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    deinit {
        stopTimer()
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
        // 파이어워크 애니메이션 뷰 추가
          view.addSubview(fireworksAnimationView)
        setupConstraints()
    }
    
    private func setupConstraints() {
        // 타이틀 라벨 제약조건
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.leading.equalToSuperview().offset(20)
        }
        
        // 컨테이너 뷰 제약조건
        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(view.snp.height).multipliedBy(0.15)
        }
        
        // 메달 이미지 제약조건
        medalImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            // 메달 크기를 컨테이너 높이에 비례하게 설정
            make.height.equalTo(containerView.snp.height).multipliedBy(0.8)
            make.width.equalTo(medalImageView.snp.height)
        }
        
        // 주차 라벨 제약조건
        weekLabel.snp.makeConstraints { make in
            make.top.equalTo(medalImageView).offset(4)
            make.leading.equalTo(medalImageView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        
        // 날짜 범위 라벨 제약조건
        dateRangeLabel.snp.makeConstraints { make in
            make.top.equalTo(weekLabel.snp.bottom).offset(4)
            make.leading.equalTo(weekLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        
        // 당첨금액 라벨 제약조건
        prizeAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(dateRangeLabel.snp.bottom).offset(4)
            make.leading.equalTo(weekLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.lessThanOrEqualToSuperview().offset(-4)
        }
        
        // 남은 시간 라벨 제약조건
        remainingTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // 행운 메세지 라벨 제약조건
        luckyMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(remainingTimeLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // 번호 받기 버튼 제약조건
        getNumberButton.snp.makeConstraints { make in
            make.top.equalTo(luckyMessageLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(view.snp.height).multipliedBy(0.06)
        }
        
        // 번호 표시 테이블뷰 제약조건
        numberTableView.snp.makeConstraints{ make in
            make.top.equalTo(getNumberButton.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(view.snp.height).multipliedBy(0.4) // 화면 높이의 40%
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
        }
        
        // 파이어워크 애니메이션 뷰 제약조건 추가
              fireworksAnimationView.snp.makeConstraints { make in
                  make.edges.equalToSuperview()  // 전체 화면을 덮도록 설정
              }
        
    }
    
    private func setupTableView() {
        numberTableView.delegate = self
        numberTableView.dataSource = self
    }
    // MARK: - Date Helpers
    private func updateDateLabels() {
        let now = Date()
        let calendar = Calendar.current
        
        // 현재 월 구하기
        let month = calendar.component(.month, from: now)
        
        // 현재 주차 구하기
        let weekOfMonth = calendar.component(.weekOfMonth, from: now)
        
        // 이번주의 시작일과 종료일 구하기
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 1 // 일요일
        guard let startOfWeek = calendar.date(from: components) else { return }
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return
        }
        
        // 날짜 포맷터 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        
        // 라벨 업데이트
        weekLabel.text = "\(month)월 \(weekOfMonth)째주"
        dateRangeLabel.text = "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
    }
    

    // MARK: - Timer
    private func startTimer() {
        stopTimer()
        
        // DispatchSourceTimer
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        
        timer.setEventHandler { [weak self] in
            self?.updateTimer()
        }
        
        timer.resume()
        self.timer = timer
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
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
            updateDateLabels() // 날짜 라벨도 같이 업데이트
        } else {
            // 추첨 시간이 지난 경우
            remainingTimeLabel.text = "⏱ 다음 추첨을 기다려주세요"
            stopTimer() // 현재 타이머 중지
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
}

// MARK: - TableView DataSource & Delegate
extension NumberRecommendViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height / 5  // 테이블뷰 전체 높이를 5등분
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5 // 5줄의 번호
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NumberCell",
                                                      for: indexPath) as? NumberCell else {
            return UITableViewCell()
        }
        
        // delegate 설정
            cell.delegate = self
        
        // 생성된 번호가 있으면 해당 번호를 표시, 없으면 빈 배열 표시
        if !generatedNumbers.isEmpty {
            cell.configure(with: generatedNumbers[indexPath.row])
        } else {
            cell.configure(with: [])
        }
        return cell
    }
}

protocol NumberCellDelegate: AnyObject {
    func didUpdateAllRowsToOrange()
}

// MARK: - NumberCell
class NumberCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // delegate 프로퍼티 추가
    weak var delegate: NumberCellDelegate?
    static var orangeRowCount = 0
    
    private var isOrangeRow: Bool = false
    
    func configure(with numbers: [Int]) {
        self.numbers = numbers
        
        if !numbers.isEmpty {
            // 60% 확률로 오렌지색 행으로 설정
            self.isOrangeRow = Double.random(in: 0...1) < 0.6
            
            // isOrangeRow가 true일 때 카운트 증가
            if self.isOrangeRow {
                NumberCell.orangeRowCount += 1
//                print("오렌지 행 카운트: \(NumberCell.orangeRowCount)") // 디버깅용
                
                // 모든 행이 오렌지색일 때 (5줄)
                if NumberCell.orangeRowCount == 5 {
//                    print("모든 행이 오렌지색으로 변경됨") // 디버깅용
                    DispatchQueue.main.async { [weak self] in
                        self?.delegate?.didUpdateAllRowsToOrange()
                    }
                    // 카운트 리셋을 delegate 메서드 호출 후로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NumberCell.orangeRowCount = 0
                    }
                }
            }
        }
        
        numberCollectionView.reloadData()
    }
    
    // Cell이 재사용될 때 호출되는 메서드
    override func prepareForReuse() {
        super.prepareForReuse()
        if isOrangeRow {
            isOrangeRow = false
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numbers.isEmpty ? 6 : numbers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberItemCell", for: indexPath) as? NumberItemCell else {
            return UICollectionViewCell()
        }
        if numbers.isEmpty {
            // 번호가 없을 때는 "?"를 표시
            cell.configureEmpty()
        } else {
            // isOrangeRow 값을 전달하여 설정
            cell.configure(with: numbers[indexPath.item], isOrange: isOrangeRow)
        }
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
        cv.backgroundColor = .clear
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
            make.edges.equalToSuperview().inset(0) // 여백 없이 꽉 채움
        }
    }
}
// MARK: - extension NumberCell
extension NumberCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width - 20
        let itemWidth = (availableWidth - (5 * 10)) / 6
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacing: CGFloat) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
}

// MARK: - NumberItemCell
class NumberItemCell: UICollectionViewCell {

    func configureEmpty() {
        numberLabel.text = "?"
        numberLabel.textColor = .lightGray
        contentView.backgroundColor = .clear      // 배경색 투명
        contentView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func configure(with number: Int, isOrange: Bool) {
        numberLabel.text = String(format: "%02d", number)
        if isOrange {
            // 기존 배경색 제거
            contentView.backgroundColor = .clear
            
            // 그라데이션 레이어 생성
            let gradientLayer = CAGradientLayer()
            gradientLayer.name = "cellGradient"
            gradientLayer.frame = contentView.bounds
            gradientLayer.cornerRadius = bounds.width / 2  // 원형 유지
            gradientLayer.type = .radial
            
            // 색상 설정
            let baseColor = UIColor(red: 245/255, green: 220/255, blue: 37/255, alpha: 1.0)
            let orangeColor = UIColor(red: 245/255, green: 184/255, blue: 0/255, alpha: 1.0)
            
            let lightColor = baseColor.withAlphaComponent(1.0)
            let midColor = baseColor.withAlphaComponent(0.9)
            let darkColor = orangeColor.withAlphaComponent(0.8)
            
            gradientLayer.colors = [
                lightColor.cgColor,
                midColor.cgColor,
                darkColor.cgColor
            ]
            
            gradientLayer.locations = [0.2, 0.5, 1.0]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
            
            // 기존 그라데이션 레이어 제거
            contentView.layer.sublayers?.removeAll { $0.name == "cellGradient" }
            contentView.layer.insertSublayer(gradientLayer, at: 0)
            
            // 그림자 효과
            contentView.layer.shadowColor = UIColor.black.cgColor
            contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
            contentView.layer.shadowRadius = 3
            contentView.layer.shadowOpacity = 0.2
            
            // 테두리
            contentView.layer.borderWidth = 0.5
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            
            numberLabel.textColor = .black
            numberLabel.font = .h5
        } else {
            // 기존 스타일 유지
            contentView.backgroundColor = .clear
            numberLabel.textColor = .black
            numberLabel.font = .h6
            contentView.layer.borderColor = UIColor.lightGray.cgColor
            
            // 그림자 제거
            contentView.layer.shadowOpacity = 0
            
            // 그라데이션 레이어 제거
            contentView.layer.sublayers?.removeAll { $0.name == "cellGradient" }
        }
    }

    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
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
        contentView.layer.cornerRadius = bounds.width / 2 // 원모양 테두리
        contentView.layer.borderWidth = 1 // 테두리 두께
        contentView.layer.borderColor = UIColor.lightGray.cgColor // 테두리 색상
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        // 그림자가 잘리지 않도록 설정
        contentView.layer.masksToBounds = false
        
        contentView.addSubview(numberLabel)
        // 숫자 라벨 색상 설정
        numberLabel.textColor = .black
        
        numberLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}


// 1픽셀 이미지 생성을 위한 Extension
extension UIImage {
    static func pixel(ofColor color: UIColor) -> UIImage {
        let pixel = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        
        UIGraphicsBeginImageContext(pixel.size)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        
        context.setFillColor(color.cgColor)
        context.fill(pixel)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

extension NumberRecommendViewController: NumberCellDelegate {
    func didUpdateAllRowsToOrange() {
        
        fireworksAnimationView.playAnimation()

    }
}


import UIKit
import SnapKit

class NumberRecommendViewController: UIViewController {
    
    // MARK: - UI Components
    private let generateButton: UIButton = {
        let button = UIButton()
        button.setTitle("번호 생성하기", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        return button
    }()
    
    private let numbersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .center
        return stackView
    }()
    
    // 번호를 감싸는 컨테이너 뷰 추가
    private func createNumberLabel() -> UIView {
        let containerView = UIView()
        containerView.layer.cornerRadius = 12
        
        let numberLabel = UILabel()
        numberLabel.font = .systemFont(ofSize: 24, weight: .bold)
        numberLabel.textAlignment = .center
        numberLabel.numberOfLines = 0
        numberLabel.text = "- - - - - -"
        numberLabel.textColor = .black
        
        containerView.addSubview(numberLabel)
        numberLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        
        return containerView
    }
    
    private var numberContainers: [(container: UIView, label: UILabel)] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "번호 추천"
        view.backgroundColor = .white
        
        view.addSubview(numbersStackView)
        view.addSubview(generateButton)
        
        // 5개의 컨테이너와 레이블 생성
        for _ in 0..<5 {
            let containerView = createNumberLabel()
            let numberLabel = containerView.subviews.first as! UILabel
            numberContainers.append((containerView, numberLabel))
            numbersStackView.addArrangedSubview(containerView)
        }
        
        // 제약조건 수정 - 스택뷰를 아래쪽으로 이동
        numbersStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(generateButton.snp.top).offset(-40)  // 버튼과의 간격 조정
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        generateButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    private func setupActions() {
        generateButton.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func generateButtonTapped() {
        // 5세트의 번호 생성
        for (index, (container, label)) in numberContainers.enumerated() {
            var numbers = Set<Int>()
            while numbers.count < 6 {
                numbers.insert(Int.random(in: 1...45))
            }
            
            let sortedNumbers = Array(numbers).sorted()
            
            // 70% 확률로 특별 스타일 적용
            let shouldGenerateSpecial = Double.random(in: 0...1) < 0.7
            
            // 번호 텍스트 생성
            let numbersText = sortedNumbers.enumerated().map { index, number in
                let numberText = String(format: "%02d", number)
                return index < sortedNumbers.count - 1 ? "\(numberText) - " : numberText
            }.joined()
            
            // 각 레이블에 대해 순차적으로 애니메이션 적용
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                UIView.transition(with: container,
                                duration: 0.3,
                                options: .transitionCrossDissolve) {
                    label.text = numbersText
                    // 특별 스타일이면 배경색 변경 (F6C928 색상)
                    container.backgroundColor = shouldGenerateSpecial ? 
                        UIColor(red: 246/255, green: 201/255, blue: 40/255, alpha: 0.5) : .clear
                }
            }
        }
    }
} 
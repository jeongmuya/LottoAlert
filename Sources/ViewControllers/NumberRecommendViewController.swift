import UIKit
import SnapKit

class NumberRecommendViewController: UIViewController {
    
    // MARK: - UI Components
    private let numbersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        return stackView
    }()
    
    private lazy var eggShapeView: EggShapeView = {
        let view = EggShapeView(frame: .zero)
        view.backgroundColor = .clear
        return view
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
        setupGestureRecognizer()
        generateNumbers() // 초기 번호 생성
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "번호 추천"
        view.backgroundColor = .white
        
        // EggShapeView 추가
        view.addSubview(eggShapeView)
        eggShapeView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-150) // 위쪽으로 조정
            make.width.height.equalTo(300)
        }
        
        view.addSubview(numbersStackView)
        
        // 5개의 컨테이너와 레이블 생성
        for _ in 0..<5 {
            let containerView = createNumberLabel()
            let numberLabel = containerView.subviews.first as! UILabel
            numberContainers.append((containerView, numberLabel))
            numbersStackView.addArrangedSubview(containerView)
        }
        
        // 스택뷰 위치 조정
        numbersStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-50)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(eggTapped))
        eggShapeView.addGestureRecognizer(tapGesture)
        eggShapeView.isUserInteractionEnabled = true
    }
    
    // MARK: - Actions
    @objc private func eggTapped() {
        generateNumbers()
    }
    
    private func generateNumbers() {
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
                    container.backgroundColor = shouldGenerateSpecial ? 
                        UIColor(red: 246/255, green: 201/255, blue: 40/255, alpha: 0.5) : .clear
                }
            }
        }
        
        // 계란 흔들기 애니메이션 수정
        UIView.animate(withDuration: 0.1, animations: {
            self.eggShapeView.transform = CGAffineTransform(rotationAngle: 0.1)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.eggShapeView.transform = CGAffineTransform(rotationAngle: -0.1)
            } completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.eggShapeView.transform = CGAffineTransform.identity
                }
            }
        }
    }
} 

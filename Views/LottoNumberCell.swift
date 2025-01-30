import UIKit
import SnapKit

class LottoNumberCell: UITableViewCell {
    static let identifier = "LottoNumberCell"
    
    // MARK: - UI Components
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    
    private let numbersLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        backgroundColor = .white
        contentView.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(dateLabel)
        contentView.addSubview(numbersLabel)
        
        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        numbersLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(dateLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    // MARK: - Configuration
    private var currentRecommendation: LottoRecommendation?
    private var cachedAttributedText: NSAttributedString?
    
    func configure(with recommendation: LottoRecommendation) {
        if currentRecommendation?.id == recommendation.id,
           let cached = cachedAttributedText {
            numbersLabel.attributedText = cached
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = dateFormatter.string(from: recommendation.date)
        
        let numbersText = createAttributedNumbers(from: recommendation)
        
        currentRecommendation = recommendation
        cachedAttributedText = numbersText
        
        numbersLabel.attributedText = numbersText
    }
    
    private func createAttributedNumbers(from recommendation: LottoRecommendation) -> NSAttributedString {
        let numbersText = NSMutableAttributedString()
        
        recommendation.numbers.enumerated().forEach { index, number in
            let numberText = String(format: "%02d", number)
            let isSpecial = recommendation.specialNumbers.contains(number)
            
            let attributes: [NSAttributedString.Key: Any] = isSpecial ? [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 205/255, green: 165/255, blue: 50/255, alpha: 1.0)
            ] : [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            
            let attributedNumber = NSAttributedString(string: numberText, attributes: attributes)
            numbersText.append(attributedNumber)
            
            if index < recommendation.numbers.count - 1 {
                numbersText.append(NSAttributedString(string: " - "))
            }
        }
        
        return numbersText
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentRecommendation = nil
        cachedAttributedText = nil
    }
} 
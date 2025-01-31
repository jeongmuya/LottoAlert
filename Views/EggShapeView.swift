import UIKit

class EggShapeView: UIView {
    
    private let eggShape = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        // 계란 모양 레이어 설정
        eggShape.fillColor = UIColor(red: 255/255, green: 248/255, blue: 231/255, alpha: 1.0).cgColor  // 연한 계란색
        eggShape.strokeColor = UIColor(red: 230/255, green: 220/255, blue: 200/255, alpha: 1.0).cgColor  // 계란 테두리색
        eggShape.lineWidth = 1.5
        layer.addSublayer(eggShape)
        
        // 그림자 효과
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawEgg()
    }
    
    private func drawEgg() {
        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        
        // 계란의 중심점과 크기 설정
        let centerX = width/2
        let centerY = height/2
        let eggWidth = width * 0.75
        let eggHeight = height * 0.85
        
        // 곡선 제어를 위한 오프셋
        let curveOffset = eggHeight * 0.1  // 곡선의 휘어짐 정도
        
        // 시작점 (위쪽 중앙)
        path.move(to: CGPoint(x: centerX, y: centerY - eggHeight/2))
        
        // 오른쪽 위 곡선
        path.addCurve(
            to: CGPoint(x: centerX + eggWidth/2, y: centerY),  // 오른쪽 중앙
            controlPoint1: CGPoint(x: centerX + eggWidth/3, y: centerY - eggHeight/2),
            controlPoint2: CGPoint(x: centerX + eggWidth/2, y: centerY - eggHeight/4)
        )
        
        // 오른쪽 아래 곡선
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY + eggHeight/2),  // 아래쪽 중앙
            controlPoint1: CGPoint(x: centerX + eggWidth/2, y: centerY + eggHeight/4),
            controlPoint2: CGPoint(x: centerX + eggWidth/3, y: centerY + eggHeight/2)
        )
        
        // 왼쪽 아래 곡선
        path.addCurve(
            to: CGPoint(x: centerX - eggWidth/2, y: centerY),  // 왼쪽 중앙
            controlPoint1: CGPoint(x: centerX - eggWidth/3, y: centerY + eggHeight/2),
            controlPoint2: CGPoint(x: centerX - eggWidth/2, y: centerY + eggHeight/4)
        )
        
        // 왼쪽 위 곡선
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY - eggHeight/2),  // 다시 위쪽 중앙으로
            controlPoint1: CGPoint(x: centerX - eggWidth/2, y: centerY - eggHeight/4),
            controlPoint2: CGPoint(x: centerX - eggWidth/3, y: centerY - eggHeight/2)
        )
        
        eggShape.path = path.cgPath
        
        // 그라데이션 효과
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [
            UIColor(red: 255/255, green: 252/255, blue: 240/255, alpha: 1.0).cgColor,  // 더 밝은 계란색
            UIColor(red: 255/255, green: 248/255, blue: 231/255, alpha: 1.0).cgColor   // 약간 어두운 계란색
        ]
        gradient.startPoint = CGPoint(x: 0.2, y: 0.2)
        gradient.endPoint = CGPoint(x: 0.8, y: 0.8)
        
        gradient.mask = eggShape
        layer.sublayers?.forEach { if $0 is CAGradientLayer { $0.removeFromSuperlayer() } }
        layer.insertSublayer(gradient, at: 0)
    }
}


//
//  FireworksAnimationView.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/14/25.
//

import UIKit
import SnapKit
import Lottie

class FireworksAnimationView: UIView {
    
    // MARK: - Properties
    private var animationView: LottieAnimationView?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAnimation()
    }
    
    // MARK: - Setup
    private func setupAnimation() {
        // 애니메이션 뷰 설정
        animationView = .init(name: "FireworksAnimation") 
        
        guard let animationView = animationView else { return }
        
        // 애니메이션 뷰를 전체 화면으로 설정
            animationView.frame = UIScreen.main.bounds  // 전체 화면 크기로 설정
            animationView.contentMode = .scaleAspectFill  // 화면을 꽉 채우도록 변경
            animationView.loopMode = .playOnce
            animationView.isHidden = true
        
        // 자동 크기 조정
        animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 뷰에 추가
        addSubview(animationView)
    }
    
    // MARK: - Public Methods
    func playAnimation(completion: ((Bool) -> Void)? = nil) {
        guard let animationView = animationView else { return }
        
        // 진동 효과 추가
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 애니메이션 표시 및 실행
        animationView.isHidden = false
        animationView.play { [weak self] completed in
            if completed {
                self?.animationView?.isHidden = true
            }
            completion?(completed)
        }
    }
    
    func stopAnimation() {
        animationView?.stop()
        animationView?.isHidden = true
    }
}

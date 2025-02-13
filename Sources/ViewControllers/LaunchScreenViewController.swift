//
//  LaunchScreenViewController.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/14/25.
//

import UIKit
import Lottie
import SnapKit

class LaunchScreenViewController: UIViewController {
    
    var completionHandler: (() -> Void)?
    private var animationView: LottieAnimationView?
    
    // 라벨 추가
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "로또 알림"  // 원하는 텍스트로 변경하세요
        label.textAlignment = .center
        label.font = .h4
        label.textColor = .black
        return label
    }()
    
    // 하단 라벨
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "아무것도 안하면 아무일도 생기지 않는다"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Lottie 뷰 설정
        animationView = .init(name: "notificationBellAnimation")
        animationView?.contentMode = .scaleAspectFit
        animationView?.loopMode = .playOnce
        
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        if let animationView = animationView {
            view.addSubview(animationView)
        }
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
    }
    
    private func setupConstraints() {
        // 애니메이션 뷰 제약조건
        animationView?.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(200) // 크기 조절 가능
        }
        
        // 라벨 제약조건
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(animationView?.snp.bottom ?? view.snp.centerY).offset(20)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // 하단 라벨
        subtitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 애니메이션 재생
        animationView?.play { [weak self] completed in
            if completed {
                // 애니메이션 완료 후 completionHandler 호출
                self?.completionHandler?()
            }
        }
    }
}

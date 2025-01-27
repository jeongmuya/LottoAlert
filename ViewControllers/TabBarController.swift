//
//  Untitled.swift
//  LottoAlert
//
//  Created by YangJeongMu on 1/20/25.
//

import UIKit
class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // LottoMapViewController를 첫 번째 탭으로 설정
        let lottoMapVC = LottoMapViewController()
        lottoMapVC.tabBarItem = UITabBarItem(
            title: "지도",
            image: UIImage(systemName: "map"),
            selectedImage: UIImage(systemName: "map.fill")
        )
        
        // 다른 뷰 컨트롤러들 설정...
        
        // 각 뷰 컨트롤러를 내비게이션 컨트롤러로 감싸기
        let navigationController = UINavigationController(rootViewController: lottoMapVC)
        
        // 탭 바 컨트롤러에 뷰 컨트롤러 설정
        viewControllers = [navigationController]
        
        // 탭바 커스터마이징
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .white
    }
}

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
        setupViewControllers()
        setupTabBar()
    }
    
    private func setupViewControllers() {
        // 지도 화면
        let mapVC = MapViewController()
        let mapNav = UINavigationController(rootViewController: mapVC)
        mapNav.tabBarItem = UITabBarItem(
            title: "지도",
            image: UIImage(systemName: "map"),
            selectedImage: UIImage(systemName: "map.fill")
        )
        
        // 번호 추천 화면
        let recommendVC = NumberRecommendViewController()
        let recommendNav = UINavigationController(rootViewController: recommendVC)
        recommendNav.tabBarItem = UITabBarItem(
            title: "번호 추천",
            image: UIImage(systemName: "number.circle"),
            selectedImage: UIImage(systemName: "number.circle.fill")
        )
        
        
        // 번호 추천 화면2
        let recommendVC2 = NumberRecommendViewController2()
        let recommendNav2 = UINavigationController(rootViewController: recommendVC2)
        recommendNav2.tabBarItem = UITabBarItem(
            title: "번호 추천2",
            image: UIImage(systemName: "number.circle"),
            selectedImage: UIImage(systemName: "number.circle.fill")
        )
        
//        // 히스토리 화면
//        let historyNav = UINavigationController(rootViewController: historyVC)
//        historyNav.tabBarItem = UITabBarItem(
//            title: "히스토리",
//            image: UIImage(systemName: "clock"),
//            selectedImage: UIImage(systemName: "clock.fill")
//        )
        
        viewControllers = [mapNav, recommendNav, recommendNav2]
    }
    
    private func setupTabBar() {
        tabBar.tintColor = .darkGray
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false
        
        // 쉐도우 추가
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1) // 음수값은 위쪽 방향
        tabBar.layer.shadowRadius = 4
        tabBar.layer.shadowOpacity = 0.3
        
        // 쉐도우가 잘 보이도록 클리핑 비활성화
        tabBar.layer.masksToBounds = false
    }
}

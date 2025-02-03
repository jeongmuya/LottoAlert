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
        
//        // 히스토리 화면
//        let historyNav = UINavigationController(rootViewController: historyVC)
//        historyNav.tabBarItem = UITabBarItem(
//            title: "히스토리",
//            image: UIImage(systemName: "clock"),
//            selectedImage: UIImage(systemName: "clock.fill")
//        )
        
        viewControllers = [mapNav, recommendNav]
    }
    
    private func setupTabBar() {
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false
    }
}

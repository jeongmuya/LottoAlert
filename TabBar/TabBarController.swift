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
        
        // 뷰컨트롤러 생성
        let mapVC = MapViewController()
        let randomVC = RandomNumberViewController()
        
        // 탭바 아이템 설정
        mapVC.tabBarItem = UITabBarItem(
            title: "지도",
            image: UIImage(systemName: "map"),
            tag: 0
            )
        
        randomVC.tabBarItem = UITabBarItem(
            title: "번호생성",
            image: UIImage(systemName: "number.circle"),
            tag: 1
            )
        
        // 탭바 컨트롤러에 뷰 컨트롤러 배열 설정
        setViewControllers([mapVC, randomVC], animated: true)
        
        // 탭바 커스터마이징 (선택사항)
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemBackground
    }
}

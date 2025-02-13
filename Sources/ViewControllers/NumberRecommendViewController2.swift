//
//  Untitled.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/13/25.
//

import SwiftUI
import UIKit
import SnapKit
import Lottie

class NumberRecommendViewController2: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let animationView: LottieAnimationView = .init(name: "GoldButton")
        self.view.addSubview(animationView)
        animationView.play()
        animationView.loopMode = .loop
        
        animationView.frame = self.view.bounds
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFit
    }
    
}



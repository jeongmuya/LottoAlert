////
////  LottieFile.swift
////  LottoAlert
////
////  Created by YangJeongMu on 2/13/25.
////
//
//import Foundation
//import Lottie
//import SwiftUI
//import UIKit
//
//// 로티 애니메이션 뷰
//struct LottieView: UIViewRepresentable {
//    var name : String
//    var loopMode: LottieLoopMode
//    
//    // 간단하게 View로 JSON 파일 이름으로 애니메이션을 실행합니다.
//    init(jsonName: String = "", loopMode : LottieLoopMode = .loop){
//        self.name = jsonName
//        self.loopMode = loopMode
//    }
//    
//    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
//        let view = UIView(frame: .zero)
//
//        let animationView = AnimationView()
//        let animation = Animation.named(name)
//        animationView.animation = animation
//        // AspectFit으로 적절한 크기의 에니매이션을 불러옵니다.
//        animationView.contentMode = .scaleAspectFit
//        // 애니메이션은 기본으로 Loop합니다.
//        animationView.loopMode = loopMode
//        // 애니메이션을 재생합니다
//        animationView.play()
//        // 백그라운드에서 재생이 멈추는 오류를 잡습니다
//        animationView.backgroundBehavior = .pauseAndRestore
//
//  //컨테이너의 너비와 높이를 자동으로 지정할 수 있도록합니다. 로티는 컨테이너 위에 작성됩니다.
//  
//  
//      animationView.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(animationView)
//         //레이아웃의 높이와 넓이의 제약
//        NSLayoutConstraint.activate([
//            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
//            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
//        ])
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//    }
//}

//
//  File.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/4/25.
//

import Foundation
import UIKit

//  FontLiterals.swift
 
enum FontName: String {
    case pretendardBlack = "Pretendard-Black"
    case pretendardBold = "Pretendard-Bold"
    case pretendardSemiBold = "Pretendard-SemiBold"
    case pretendardMedium = "Pretendard-Medium"
    case pretendardRegular = "Pretendard-Regular"
    case pretendardExtraBold = "Pretendard-ExtraBold"
}
 
extension UIFont {
    static func font(_ style: FontName, ofSize size: CGFloat) -> UIFont {
        guard let customFont = UIFont(name: style.rawValue, size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        return customFont
    }
    
    // pretendardBlack 24
    @nonobjc class var h3: UIFont {
        return UIFont.font(.pretendardBlack, ofSize: 24)
    }
    
    // pretendardBold 24
    
    @nonobjc class var h4: UIFont {
        return UIFont.font(.pretendardBold, ofSize: 24)
    }

}

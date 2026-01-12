//
//  Fonts.swift
//  Megabox
//
//  Created by 김승겸 on 9/19/25.
//

import Foundation
import SwiftUI

extension Font {
    enum Pretend {
        case bold
        case semibold
        case medium
        case regular
        
        var value: String {
            switch self {
            case .bold:
                return "Pretendard-Bold"
            case .semibold:
                return "Pretendard-SemiBold"
            case .medium:
                return "Pretendard-Medium"
            case .regular:
                return "Pretendard-Regular"
            }
        }
    }
    
    static func pretend(type: Pretend, size: CGFloat) -> Font {
        return .custom(type.value, size: size)
    }
    
    static var Headline1: Font {
        return .pretend(type: .bold, size: 32)
    }
    
    static var Headline2: Font {
        return .pretend(type: .semibold, size: 28)
    }
    
    static var Subtitle1: Font {
        return .pretend(type: .semibold, size: 22)
    }
    
    static var Subtitle2: Font {
        return .pretend(type: .semibold, size: 18)
    }
    
    static var Subtitle3: Font {
        return .pretend(type: .medium, size: 18)
    }
    
    static var Body1: Font {
        return .pretend(type: .medium, size: 14)
    }
    
    static var Body2: Font {
        return .pretend(type: .regular, size: 12)
    }
    
    static var Body3: Font {
        return .pretend(type: .regular, size: 10)
    }
    
    static var pretendardMedium16: Font {
        return .pretend(type: .medium, size: 16)
    }
    
    static var pretendardBold60: Font {
        return .pretend(type: .bold, size: 60)
    }
    
    static var pretendardBold16: Font {
        return .pretend(type: .bold, size: 16)
    }
}

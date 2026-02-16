//
//  TokenProviding.swift
//  Lumo
//
//  Created by 김승겸 on 2/9/26.
//

import Foundation

/// 토큰 관리 기능을 정의하는 프로토콜
protocol TokenProviding: AnyObject {
    
    /// 현재 유효한 액세스 토큰
    var accessToken: String? { get set }
    
}

//
//  TokenProviding.swift
//  Lumo
//
//  Created by 김승겸 on 2/9/26.
//

import Foundation

/// 토큰 관리 기능을 정의하는 프로토콜
protocol TokenProviding {
    
    /// 현재 유효한 액세스 토큰
    var accessToken: String? { get set }
    
    /// 토큰 갱신 요청
    /// - Parameter completion: 갱신된 토큰 또는 에러를 반환하는 클로저
    func refreshToken(completion: @escaping (String?, Error?) -> Void)
}

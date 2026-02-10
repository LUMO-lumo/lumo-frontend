//
//  AuthRouter.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//

import Foundation

import Alamofire
import Moya

enum AuthRouter {
    case sendRefreshToken(refreshToken: String)
}

extension AuthRouter: @MainActor APITargetType {
    
    var path: String {
        switch self {
        case .sendRefreshToken:
            return "/api/member/reissue"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .sendRefreshToken:
            return .post
        }
    }
    
    var task: Task {
        switch self {
        case .sendRefreshToken:
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .sendRefreshToken(let refreshToken):
            return [
                "Content-Type": "application/json",
                "Refresh-Token": refreshToken
            ]
        }
    }
}

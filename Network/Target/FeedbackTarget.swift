//
//  SendFeedbackTarget.swift
//  Lumo
//
//  Created by 정승윤 on 2/15/26.
//

import Foundation
import Alamofire
import Moya

enum FeedbackTarget {
    case sendFeedback(request: FeedbackRequest)
}

extension FeedbackTarget: TargetType {
    
    var baseURL: URL { return URL(string: AppConfig.baseURL)! }
    
    var path: String {
            switch self {
            case .sendFeedback:
                return "/api/feedbacks" // 🔥 실제 API 경로로 변경 필요
            }
        }
        
        var method: Moya.Method {
            switch self {
            case .sendFeedback:
                return .post // 데이터 전송이므로 POST
            }
        }
        
    var task: Moya.Task {
            switch self {
            case .sendFeedback(let request):
                // JSON 형태로 인코딩해서 바디에 실어 보냄
                return .requestJSONEncodable(request)
            }
        }
        
    var headers: [String : String]? {
       
        var header = ["Content-Type": "application/json"]
        
        if let userInfo: UserInfo = KeychainManager.standard.loadSession(for: "userSession") {
            header["Authorization"] = "Bearer \(userInfo.accessToken ?? "")"
        }
        
        return header
    }
    }

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
    
    var baseURL: URL {
        return URL(string: AppConfig.baseURL)!
    }
    
    var path: String {
        switch self {
        case .sendFeedback:
            return "/api/feedbacks" // 🔥 실제 API 경로 확인 필요
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .sendFeedback:
            return .post
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
        // 1. 기본 헤더 설정
        var header = ["Content-Type": "application/json"]
        
        // 2. 키체인에서 토큰 가져오기 (수정됨)
        do {
            // loadSession이 throws하므로 try 사용
            let userInfo = try KeychainManager.standard.loadSession(for: "userSession")
            
            if let accessToken = userInfo.accessToken {
                // 3. 토큰이 있을 때만 Authorization 헤더 추가
                header["Authorization"] = "Bearer \(accessToken)"
                
                // 디버깅용 로그 (필요 시 주석 처리)
                // print("🔑 [FeedbackTarget] 헤더에 토큰 추가됨")
            } else {
                print("⚠️ [FeedbackTarget] 세션은 있으나 Access Token이 없습니다.")
            }
            
        } catch {
            // 4. 에러 발생 시 (로그인이 안 되어 있거나 키체인 오류)
            // 의견 보내기는 보통 로그인 상태에서 하므로 로그를 남겨두면 좋습니다.
            print("ℹ️ [FeedbackTarget] 토큰 로드 실패: \(error)")
        }
        
        return header
    }
}

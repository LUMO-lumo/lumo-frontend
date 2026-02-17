//
//  NoticeTarget.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import Moya
import Alamofire

enum NoticeTarget {
    case createNotice(type: String, title: String, content: String)
    case deleteNotice(noticeId: Int)
    case updateNotice(noticeId: Int, type: String, title: String, content: String)
    case showNotice(keyword: String?)
    case showNoticeDetail(noticeId: Int)
}

extension NoticeTarget: TargetType {
    var baseURL: URL {
        return URL(string: AppConfig.baseURL)!
    }
    
    var path: String {
        switch self {
        case .createNotice:
            return "/api/admin/notices"
            
        case .deleteNotice(let noticeId):
            return "/api/admin/notices/\(noticeId)"
            
        case .updateNotice(let noticeId, _, _, _):
            return "/api/admin/notices/\(noticeId)"
            
        case .showNotice:
            return "/api/notices"
            
        case .showNoticeDetail(let noticeId):
            return "/api/notices/\(noticeId)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .createNotice:
            return .post
        case .deleteNotice:
            return .delete
        case .updateNotice:
            return .patch
        case .showNotice, .showNoticeDetail:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .createNotice(let type, let title, let content):
            let parameters: [String: Any] = [
                "type": type,
                "title": title,
                "content": content
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .deleteNotice:
            return .requestPlain
            
        case .updateNotice(_, let type, let title, let content):
            let parameters: [String: Any] = [
                "type": type,
                "title": title,
                "content": content
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .showNotice(let keyword):
            if let keyword = keyword, !keyword.isEmpty {
                return .requestParameters(parameters: ["search": keyword], encoding: URLEncoding.queryString)
            } else {
                return .requestPlain
            }
            
        case .showNoticeDetail:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        // 1. 기본 헤더 설정
        var header = ["Content-Type": "application/json"]
        
        // 2. 키체인에서 저장된 토큰 꺼내오기
        do {
            // try를 사용하여 세션을 불러옵니다.
            let userInfo = try KeychainManager.standard.loadSession(for: "userSession")
            
            if let accessToken = userInfo.accessToken {
                // 3. 헤더에 토큰 추가
                header["Authorization"] = "Bearer \(accessToken)"
                
                // 디버깅용 로그 (필요 시 주석 처리)
                print("🔑 [NoticeTarget] 헤더에 토큰 추가됨")
            } else {
                print("⚠️ [NoticeTarget] 세션은 있으나 Access Token이 없습니다.")
            }
            
        } catch {
            // 4. 에러 발생 시 (로그인이 안 되어 있거나 키체인 오류)
            // 에러 로그를 남겨서 디버깅을 돕습니다.
            print("ℹ️ [NoticeTarget] 토큰 로드 실패 (비로그인 상태 또는 에러): \(error)")
        }
        
        return header
    }
}

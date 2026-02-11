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
    var baseURL: URL { return URL(string: AppConfig.baseURL)! }
    
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
           
            var header = ["Content-Type": "application/json"]
            
            if let userInfo: UserInfo = KeychainManager.standard.loadSession(for: "userSession") {
                header["Authorization"] = "Bearer \(userInfo.accessToken ?? "")"
            }
            
            return header
        }
    }

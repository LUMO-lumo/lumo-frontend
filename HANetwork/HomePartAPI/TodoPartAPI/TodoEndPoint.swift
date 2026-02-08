//
//  TodoEndPoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation
import Moya
import Alamofire


enum TodoEndpoint: MainEndpoint {
    // [수정] 일별 조회를 위해 date 파라미터 추가 (명세서: "일별" 할 일 목록)
    case fetchTodoList(date: String)
    
    // [수정] 생성 시 date와 content 모두 필요 (명세서 request body: { eventDate, content })
    case createTodo(date: String, content: String)
    
    case deleteTodo(id: Int)
    
    // [수정] 수정 시에도 date정보가 유지되거나 변경될 수 있으므로 포함 권장 (명세서 Patch 응답에 eventDate 포함됨)
    case updateTodo(id: Int, date: String, content: String)
    
    case Todobriefing(id: Int)

    var path: String {
        switch self {
        case .fetchTodoList, .createTodo:
            return "/api/to-do"
        case .deleteTodo(let id), .updateTodo(let id, _, _):
            return "/api/to-do/\(id)"
        case .Todobriefing(id: let id):
            return "/api/to-do/briefing/\(id)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchTodoList, .Todobriefing: return .get
        case .createTodo: return .post
        case .deleteTodo: return .delete
        case .updateTodo: return .patch
        }
    }

    var task: Moya.Task {
        switch self {
        case .fetchTodoList(let date):
            // GET 요청 시 쿼리 파라미터로 날짜 전달 (서버 구현에 따라 다를 수 있으나, 일별 조회는 보통 쿼리스트링 사용)
            return .requestParameters(parameters: ["eventDate": date], encoding: URLEncoding.default)
            
        case .createTodo(let date, let content):
            // POST Body: { "eventDate": "...", "content": "..." }
            let params = [
                "eventDate": date,
                "content": content
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .updateTodo(_, let date, let content):
            // PATCH Body
            let params = [
                "eventDate": date,
                "content": content
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .deleteTodo:
            return .requestPlain
            
        case .Todobriefing:
            return .requestPlain
        }
    }
}

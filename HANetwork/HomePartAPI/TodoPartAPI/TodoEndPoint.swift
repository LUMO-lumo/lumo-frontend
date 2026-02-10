//
//  TodoEndPoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation
import Moya
import Alamofire


enum TodoEndpoint: @MainActor MainEndpoint {
    case fetchTodoList(date: String)
    case createTodo(date: String, content: String)
    case deleteTodo(id: Int)
    case updateTodo(id: Int, date: String, content: String)
    
    // [수정] Swagger 명세에 맞춰 id 파라미터 제거
    case getTodoBriefing

    var path: String {
        switch self {
        case .fetchTodoList, .createTodo:
            return "/api/to-do"
        case .deleteTodo(let id), .updateTodo(let id, _, _):
            return "/api/to-do/\(id)"
        case .getTodoBriefing:
            // [수정] 경로에서 id 제거
            return "/api/to-do/briefing"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchTodoList, .getTodoBriefing: return .get
        case .createTodo: return .post
        case .deleteTodo: return .delete
        case .updateTodo: return .patch
        }
    }

    var task: Moya.Task {
        switch self {
        case .fetchTodoList(let date):
            return .requestParameters(parameters: ["eventDate": date], encoding: URLEncoding.default)
            
        case .createTodo(let date, let content):
            let params = [
                "eventDate": date,
                "content": content
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .updateTodo(_, let date, let content):
            let params = [
                "eventDate": date,
                "content": content
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .deleteTodo, .getTodoBriefing:
            return .requestPlain
        }
    }
}

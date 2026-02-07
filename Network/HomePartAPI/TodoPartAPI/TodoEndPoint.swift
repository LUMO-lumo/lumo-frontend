//
//  TodoEndPoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation
import Moya
import Alamofire

enum TodoEndpoint: YookEndpoint {
    case fetchTodoList //일별 할 일 목록 조회
    case createTodo(content: String)//할 일 생성
    case deleteTodo(id: Int) //할 일 삭제
    case updateTodo(id: Int, content: String)//할 일 수정
    case Todobriefing(id: Int) //오늘 할 일 브리핑

    var path: String {
        switch self {
        case .fetchTodoList, .createTodo: return "/api/to-do"
        case .deleteTodo(let id), .updateTodo(let id, _): return "/api/to-do/\(id)"
        case .Todobriefing(id: let id): return "/api/to-do/briefing/\(id)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchTodoList: return .get
        case .createTodo: return .post
        case .deleteTodo: return .delete
        case .updateTodo: return .patch
        case .Todobriefing: return .get
        }
    }

    // Swift 표준 Task와의 충돌을 방지하기 위해 Moya.Task로 명시합니다.
    var task: Moya.Task {
        switch self {
        case .createTodo(let content), .updateTodo(_, let content):
            return .requestParameters(parameters: ["content": content], encoding: JSONEncoding.default)
        default:
            return .requestPlain
        }
    }
}

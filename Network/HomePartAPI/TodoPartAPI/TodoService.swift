//
//  TodoService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation

// 임시 연결을 위한 빈 모델입니다. 나중에 실제 DTO 파일로 대체하세요.
struct TodoResponse: Decodable {}

class TodoService {
    private let client = YookAPIClient<TodoEndpoint>()

    func fetchTodoList(completion: @escaping (Result<[TodoResponse], YookAPIError>) -> Void) {
        client.request(.fetchTodoList, completion: completion)
    }

    func createTodo(content: String, completion: @escaping (Result<TodoResponse, YookAPIError>) -> Void) {
        client.request(.createTodo(content: content), completion: completion)
    }
}

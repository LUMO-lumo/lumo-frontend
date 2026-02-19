//
//  TodoService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation

class TodoService {
    
    private let client = MainAPIClient<TodoEndpoint>()

    func fetchTodoList(
        date: String,
        completion: @escaping (Result<[TodoDTO], MainAPIError>) -> Void
    ) {
        client.request(.fetchTodoList(date: date), completion: completion)
    }

    func createTodo(
        date: String,
        content: String,
        completion: @escaping (Result<TodoDTO, MainAPIError>) -> Void
    ) {
        client.request(
            .createTodo(date: date, content: content),
            completion: completion
        )
    }
    
    func updateTodo(
        id: Int,
        date: String,
        content: String,
        completion: @escaping (Result<TodoDTO, MainAPIError>) -> Void
    ) {
        client.request(
            .updateTodo(id: id, date: date, content: content),
            completion: completion
        )
    }
    
    func deleteTodo(
        id: Int,
        completion: @escaping (Result<String, MainAPIError>) -> Void
    ) {
        client.request(.deleteTodo(id: id), completion: completion)
    }
    
    // 브리핑 조회 (파라미터 없음)
    // 미션을 푼 후에 작동하도록 만들어내기
    func fetchTodoBriefing(
        completion: @escaping (Result<String, MainAPIError>) -> Void
    ) {
        client.request(.getTodoBriefing, completion: completion)
    }
}

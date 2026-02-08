//
//  TodoService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation

class TodoService {
    private let client = MainAPIClient<TodoEndpoint>()

    // 할 일 목록 조회
    // date: "yyyy-MM-dd" 형식의 문자열을 받음
    func fetchTodoList(date: String, completion: @escaping (Result<[TodoDTO], MainAPIError>) -> Void) {
        client.request(.fetchTodoList(date: date), completion: completion)
    }

    // 할 일 생성
    func createTodo(date: String, content: String, completion: @escaping (Result<TodoDTO, MainAPIError>) -> Void) {
        client.request(.createTodo(date: date, content: content), completion: completion)
    }
    
    // 할 일 수정
    func updateTodo(id: Int, date: String, content: String, completion: @escaping (Result<TodoDTO, MainAPIError>) -> Void) {
        client.request(.updateTodo(id: id, date: date, content: content), completion: completion)
    }
    
    // 할 일 삭제
    // 명세서상 delete의 result는 "string"
    func deleteTodo(id: Int, completion: @escaping (Result<String, MainAPIError>) -> Void) {
        client.request(.deleteTodo(id: id), completion: completion)
    }
}

//
//  TodoLocalService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/12/26.
//

import Foundation
import SwiftData

// 로컬 DB(SwiftData) 관리 서비스
class TodoLocalService {
    
    static let shared = TodoLocalService()
    
    var container: ModelContainer?
    var context: ModelContext?
    
    private init() {
        do {

            let schema = Schema([
                TodoEntity.self,
                UserModel.self,
                RoutineTask.self,
                RoutineType.self,
                AlarmModel.self
                
            ])
            
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            if let container = self.container {
                self.context = ModelContext(container)
            }
        } catch {
            print("❌ [LocalService] SwiftData 초기화 실패: \(error)")
        }
    }
    
    // 1. 특정 날짜 조회
    func fetchTodos(date: Date) -> [TodoEntity] {
        guard let context = context else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        let predicate = #Predicate<TodoEntity> { todo in
            todo.date >= startOfDay && todo.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<TodoEntity>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // 2. 추가
    func addTodo(title: String, date: Date, apiId: Int? = nil) -> TodoEntity? {
        guard let context = context else { return nil }
        let newTodo = TodoEntity(apiId: apiId, title: title, date: date)
        context.insert(newTodo)
        saveContext()
        return newTodo
    }
    
    // 3. 삭제
    func deleteTodo(id: UUID) {
        guard let context = context, let target = findTodo(by: id) else { return }
        context.delete(target)
        saveContext()
    }
    
    // 4. 내용 수정
    func updateTodo(id: UUID, title: String) {
        guard let todo = findTodo(by: id) else { return }
        todo.title = title
        saveContext()
    }
    
    // 5. 서버 ID(apiId)만 갱신 (동기화 완료 시)
    func updateApiId(localId: UUID, apiId: Int) {
        guard let todo = findTodo(by: localId) else { return }
        todo.apiId = apiId
        saveContext()
    }
    
    // 6. 완료 상태 토글
    func toggleTodo(id: UUID) {
        guard let todo = findTodo(by: id) else { return }
        todo.isCompleted.toggle()
        saveContext()
    }
    
    // 7. 서버로 안 보내진(미동기화) 데이터 찾기
    func fetchUnsyncedTodos() -> [TodoEntity] {
        guard let context = context else { return [] }
        let predicate = #Predicate<TodoEntity> { $0.apiId == nil }
        let descriptor = FetchDescriptor<TodoEntity>(predicate: predicate)
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // 8. 서버 데이터로 로컬 덮어쓰기 (중복 방지 병합)
    func syncWithServerData(dtos: [TodoDTO], date: Date) {
        guard let context = context else { return }
        let localTodos = fetchTodos(date: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for dto in dtos {
            let dateObj = formatter.date(from: dto.eventDate) ?? date
            
            if let existing = localTodos.first(where: { $0.apiId == dto.id }) {
                // 이미 서버 ID가 있는 경우 내용 업데이트
                existing.title = dto.content
            } else if let matchingLocal = localTodos.first(where: { $0.apiId == nil && $0.title == dto.content }) {
                // 오프라인에서 만들어 둔 데이터가 서버에 올라갔는데 아직 로컬에 ID가 안 내려온 경우 (병합)
                matchingLocal.apiId = dto.id
                matchingLocal.date = dateObj
            } else {
                // 로컬에 아예 없으면 새로 추가
                let newTodo = TodoEntity(apiId: dto.id, title: dto.content, date: dateObj)
                context.insert(newTodo)
            }
        }
        
        // 서버에서 삭제된 데이터는 로컬에서도 삭제 (단, 내가 오프라인에서 막 만든 건 제외)
        let serverIds = Set(dtos.map { $0.id })
        for local in localTodos {
            if let apiId = local.apiId, !serverIds.contains(apiId) {
                context.delete(local)
            }
        }
        
        saveContext()
    }
    
    private func findTodo(by id: UUID) -> TodoEntity? {
        guard let context = context else { return nil }
        let idToFind = id
        let predicate = #Predicate<TodoEntity> { $0.id == idToFind }
        let descriptor = FetchDescriptor<TodoEntity>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }
    
    private func saveContext() {
        do { try context?.save() }
        catch { print("❌ [LocalService] 저장 실패: \(error)") }
    }
}

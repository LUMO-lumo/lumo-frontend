//
//  HomeViewModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftUI
import Combine
import Moya

class HomeViewModel: ObservableObject {
    // MARK: - Services
    private let homeService = HomeService()
    private let todoService = TodoService()
    
    // MARK: - Published Properties
    @Published var tasks: [Task] = []
    @Published var missionStat: MissionStat = MissionStat(consecutiveDays: 0, monthlyAchievementRate: 0)
    
    @Published var dailyQuote: String = "오늘도 힘찬 하루 보내세요!"
    @Published var briefingText: String? = nil
    @Published var errorMessage: String? = nil
    
    init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    func loadAllData() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: today)
        
        fetchHomeInfo()
        fetchTodoList(date: dateString)
    }
    
    private func fetchHomeInfo() {
        homeService.fetchHomeData { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                self.dailyQuote = data.encouragement
                self.missionStat = MissionStat(
                    consecutiveDays: data.missionRecord.consecutiveSuccessCnt,
                    monthlyAchievementRate: Double(data.missionRecord.missionSuccessRate) / 100.0
                )
            case .failure(let error):
                print("Home Data Error: \(error)")
                self.errorMessage = "홈 정보를 불러오는데 실패했습니다."
            }
        }
    }
    
    private func fetchTodoList(date: String) {
        todoService.fetchTodoList(date: date) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let dtos):
                self.tasks = dtos.map { dto in
                    Task(
                        id: UUID(),
                        apiId: dto.id,
                        title: dto.content,
                        isCompleted: false,
                        date: self.date(from: dto.eventDate) ?? Date()
                    )
                }
                print("✅ 할 일 목록 로드 완료: \(self.tasks.count)개")
            case .failure(let error):
                print("Todo List Error: \(error)")
            }
        }
    }
    
    //추후 미션 후에 브리핑하게 만들기 지금 연결할 기능은 아님
    func fetchBriefing() {
        todoService.fetchTodoBriefing { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let briefing):
                self.briefingText = briefing
            case .failure(let error):
                print("Briefing Error: \(error)")
            }
        }
    }
    
    // MARK: - User Interactions
    
    func addTask(title: String, date: Date = Date()) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        print("📡 서버에 할 일 추가 요청 중... (\(trimmedTitle), \(dateString))")
        
        todoService.createTodo(date: dateString, content: trimmedTitle) { [weak self] result in
            // [핵심 수정] self를 여기서 안전하게 언래핑합니다.
            guard let self = self else { return }
            
            switch result {
            case .success(let dto):
                print("✅ 할 일 추가 성공! ID: \(dto.id)")
                let newTask = Task(
                    id: UUID(),
                    apiId: dto.id,
                    title: dto.content,
                    isCompleted: false,
                    // 이제 self가 nil이 아니므로 안전하게 호출 가능
                    date: self.date(from: dto.eventDate) ?? Date()
                )
                self.tasks.append(newTask)
                
            case .failure(let error):
                print("❌ Create Todo Error: \(error)")
                self.errorMessage = "할 일을 추가하지 못했습니다."
            }
        }
    }
    
    func deleteTask(id: UUID) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == id }),
              let apiId = tasks[taskIndex].apiId else {
            tasks.removeAll { $0.id == id }
            return
        }
        
        print("📡 서버에 할 일 삭제 요청 중... ID: \(apiId)")
        
        todoService.deleteTodo(id: apiId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("✅ 할 일 삭제 성공")
                self.tasks.remove(at: taskIndex)
            case .failure(let error):
                print("❌ Delete Todo Error: \(error)")
                self.errorMessage = "할 일을 삭제하지 못했습니다."
            }
        }
    }
    
    func updateTask(id: UUID, newTitle: String) {
        guard let index = tasks.firstIndex(where: { $0.id == id }),
              let apiId = tasks[index].apiId else { return }
        
        let task = tasks[index]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: task.date)
        
        todoService.updateTodo(id: apiId, date: dateString, content: newTitle) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let dto):
                self.tasks[index].title = dto.content
            case .failure(let error):
                print("Update Todo Error: \(error)")
            }
        }
    }
    
    func toggleTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    // MARK: - Helpers
    private func date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
    
    var todayTasks: [Task] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDate($0.date, inSameDayAs: Date()) }
    }
    
    var previewTasks: [Task] {
        return Array(todayTasks.prefix(3))
    }
}

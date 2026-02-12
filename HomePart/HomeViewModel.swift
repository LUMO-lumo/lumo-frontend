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
    private let localService = TodoLocalService.shared
    
    private let tokenCheckClient = MainAPIClient<HomeEndpoint>()
    
    // MARK: - Published Properties
    // 현재 UI(상세 설정창 등)에서 보여주고 있는 "특정 날짜"의 할 일 목록
    @Published var tasks: [Task] = []
    
    // 홈 화면에서 항상 고정으로 보여줄 "오늘" 날짜의 할 일 목록
    @Published var todayTasksList: [Task] = []
    
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
        // 1. 초기 로드 시 오늘 데이터와 홈 정보를 가져옴
        refreshData(for: today)
        if tokenCheckClient.isLoggedIn {
            fetchHomeInfo()
        }
    }
    
    // 특정 날짜의 데이터를 로드하고 서버와 동기화 (달력에서 날짜 변경 시 호출)
    func loadTasksForSpecificDate(date: Date) {
        refreshData(for: date)
        if tokenCheckClient.isLoggedIn {
            fetchTodoListFromServer(date: date)
        }
    }
    
    // 로컬 데이터를 즉시 반영하고, 날짜에 따라 적절한 리스트를 업데이트
    private func refreshData(for date: Date) {
        let entities = localService.fetchTodos(date: date)
        let mappedTasks = entities.map { $0.toTask() }
        
        // 현재 뷰(달력 상세 등)에서 보고 있는 리스트 업데이트
        self.tasks = mappedTasks
        
        // 홈 화면을 위한 "오늘" 리스트는 별도로 관리 (날짜가 오늘일 때만 혹은 강제 동기화)
        let today = Date()
        if Calendar.current.isDate(date, inSameDayAs: today) {
            self.todayTasksList = mappedTasks
        } else {
            // 다른 날짜를 보고 있더라도 홈 화면용 데이터는 로컬에서 오늘 것을 따로 가져와 유지
            let todayEntities = localService.fetchTodos(date: today)
            self.todayTasksList = todayEntities.map { $0.toTask() }
        }
        
        print("📂 [Local] \(date.description) 데이터 동기화 완료")
    }
    
    private func fetchTodoListFromServer(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        todoService.fetchTodoList(date: dateString) { [weak self] result in
            guard let self = self else { return }
            if case .success(let dtos) = result {
                self.localService.syncWithServerData(dtos: dtos, date: date)
                self.refreshData(for: date)
            }
        }
    }
    
    private func fetchHomeInfo() {
        homeService.fetchHomeData { [weak self] result in
            if case .success(let data) = result {
                self?.dailyQuote = data.encouragement
                self?.missionStat = MissionStat(
                    consecutiveDays: data.missionRecord.consecutiveSuccessCnt,
                    monthlyAchievementRate: Double(data.missionRecord.missionSuccessRate) / 100.0
                )
            }
        }
    }
    
    // MARK: - User Interactions
    
    func addTask(title: String, date: Date) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newEntity = localService.addTodo(title: trimmedTitle, date: date)
        refreshData(for: date)
        
        if tokenCheckClient.isLoggedIn {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            
            todoService.createTodo(date: dateString, content: trimmedTitle) { [weak self] result in
                if case .success(let dto) = result, let entityId = newEntity?.id {
                    self?.localService.updateApiId(localId: entityId, apiId: dto.id)
                }
            }
        }
    }
    
    func deleteTask(id: UUID) {
        // 어느 리스트에 있든 삭제를 위해 검색
        let allCurrentTasks = tasks + todayTasksList
        guard let task = allCurrentTasks.first(where: { $0.id == id }) else { return }
        let taskDate = task.date
        
        localService.deleteTodo(id: id)
        refreshData(for: taskDate)
        
        if let apiId = task.apiId, tokenCheckClient.isLoggedIn {
            todoService.deleteTodo(id: apiId) { _ in }
        }
    }
    
    func updateTask(id: UUID, newTitle: String) {
        let allCurrentTasks = tasks + todayTasksList
        guard let task = allCurrentTasks.first(where: { $0.id == id }) else { return }
        let taskDate = task.date
        
        localService.updateTodo(id: id, title: newTitle)
        refreshData(for: taskDate)
        
        if let apiId = task.apiId, tokenCheckClient.isLoggedIn {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: taskDate)
            todoService.updateTodo(id: apiId, date: dateString, content: newTitle) { _ in }
        }
    }
    
    func toggleTask(id: UUID) {
        localService.toggleTodo(id: id)
        // 두 리스트 모두에서 상태를 즉시 반전 (UI 반응성)
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
        }
        if let index = todayTasksList.firstIndex(where: { $0.id == id }) {
            todayTasksList[index].isCompleted.toggle()
        }
    }
    
    var previewTasks: [Task] {
        return Array(todayTasksList.prefix(3))
    }
}

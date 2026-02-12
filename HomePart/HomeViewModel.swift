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
        
        // 1. [로컬 우선 원칙] 무조건 로컬 데이터부터 가져와서 UI 즉시 렌더링
        fetchTodoListFromLocal(date: today)
        
        // 2. 네트워크(서버)가 연결되어 있다면 백그라운드 동기화 진행
        if tokenCheckClient.isLoggedIn {
            print("✅ [Online] 서버 연결 확인됨. 백그라운드 동기화 시작.")
            
            // 미전송 데이터를 먼저 싹 밀어넣고 -> 그 다음 서버 목록을 가져옴 (순서 보장)
            syncUnsyncedData { [weak self] in
                self?.fetchHomeInfo()
                self?.fetchTodoListFromServer(date: today)
            }
        } else {
            print("⚠️ [Offline] 서버 연결 불가. 로컬 단독 모드로 작동합니다.")
        }
    }
    
    // 달력에서 다른 날짜를 선택했을 때 실행되는 함수
    func loadTasksForSpecificDate(date: Date) {
        // 무조건 로컬 먼저 즉시 로드
        fetchTodoListFromLocal(date: date)
        
        // 온라인이면 서버에서 가져와 최신화
        if tokenCheckClient.isLoggedIn {
            fetchTodoListFromServer(date: date)
        }
    }
    
    // 로컬 DB에서 불러와서 UI에 띄우기 (핵심 표시 함수)
    private func fetchTodoListFromLocal(date: Date) {
        let entities = localService.fetchTodos(date: date)
        self.tasks = entities.map { $0.toTask() }
        print("📂 [Local] UI 데이터 로드 완료: \(self.tasks.count)개")
    }
    
    // 서버에서 가져와서 로컬DB 덮어쓰기 (백그라운드)
    private func fetchTodoListFromServer(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        todoService.fetchTodoList(date: dateString) { [weak self] result in
            guard let self = self else { return }
            
            if case .success(let dtos) = result {
                // 서버 데이터를 로컬에 지능적으로 병합
                self.localService.syncWithServerData(dtos: dtos, date: date)
                // 로컬DB가 갱신되었으니 UI도 한 번 더 새로고침
                self.fetchTodoListFromLocal(date: date)
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
    
    // 오프라인 상태에서 생성된 데이터(미동기화)를 서버로 전송
    private func syncUnsyncedData(completion: @escaping () -> Void) {
        let unsynced = localService.fetchUnsyncedTodos()
        
        if unsynced.isEmpty {
            completion()
            return
        }
        
        print("🔄 [Sync] 미동기화 데이터 \(unsynced.count)개 전송 중...")
        let group = DispatchGroup()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for todo in unsynced {
            group.enter()
            let dateString = formatter.string(from: todo.date)
            
            todoService.createTodo(date: dateString, content: todo.title) { [weak self] result in
                defer { group.leave() }
                if case .success(let dto) = result {
                    // 성공 시 로컬 데이터에 서버 ID를 박아줌
                    self?.localService.updateApiId(localId: todo.id, apiId: dto.id)
                }
            }
        }
        
        group.notify(queue: .main) {
            print("🏁 [Sync] 미동기화 데이터 전송 완료")
            completion()
        }
    }
    
    // MARK: - User Interactions (로컬 즉시 반영 -> 서버 백그라운드)
    
    func addTask(title: String, date: Date = Date()) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        // 1. [로컬 우선] 즉시 로컬에 저장하고 화면 새로고침
        let newEntity = localService.addTodo(title: trimmedTitle, date: date)
        fetchTodoListFromLocal(date: date)
        
        // 2. [서버 동기화] 온라인이면 백그라운드로 서버 전송
        if tokenCheckClient.isLoggedIn {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            
            todoService.createTodo(date: dateString, content: trimmedTitle) { [weak self] result in
                if case .success(let dto) = result, let entityId = newEntity?.id {
                    // 성공하면 로컬 DB에 서버 ID 업데이트 (사용자는 모름, 뒤에서 처리됨)
                    self?.localService.updateApiId(localId: entityId, apiId: dto.id)
                }
            }
        }
    }
    
    func deleteTask(id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        
        // 1. [로컬 우선] 즉시 화면/로컬에서 삭제
        localService.deleteTodo(id: id)
        fetchTodoListFromLocal(date: task.date)
        
        // 2. [서버 동기화] 서버 ID가 있고 온라인이면 서버에도 삭제 요청
        if let apiId = task.apiId, tokenCheckClient.isLoggedIn {
            todoService.deleteTodo(id: apiId) { _ in } // 결과 무시 (이미 로컬에서 지웠으므로)
        }
    }
    
    func updateTask(id: UUID, newTitle: String) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        
        // 1. [로컬 우선] 즉시 로컬 업데이트
        localService.updateTodo(id: id, title: newTitle)
        fetchTodoListFromLocal(date: task.date)
        
        // 2. [서버 동기화]
        if let apiId = task.apiId, tokenCheckClient.isLoggedIn {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: task.date)
            
            todoService.updateTodo(id: apiId, date: dateString, content: newTitle) { _ in }
        }
    }
    
    func toggleTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            // 로컬 상태 변경
            localService.toggleTodo(id: id)
            tasks[index].isCompleted.toggle()
        }
    }
    
    func fetchBriefing() {
        todoService.fetchTodoBriefing { [weak self] result in
            if case .success(let briefing) = result {
                self?.briefingText = briefing
            }
        }
    }
    
    var todayTasks: [Task] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDate($0.date, inSameDayAs: Date()) }
    }
    
    var previewTasks: [Task] {
        return Array(todayTasks.prefix(3))
    }
}

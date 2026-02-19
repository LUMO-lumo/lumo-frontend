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
    
    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Published Properties
    @Published var tasks: [Task] = []
    @Published var todayTasksList: [Task] = []
    @Published var missionStat: MissionStat = MissionStat(consecutiveDays: 0, monthlyAchievementRate: 0)
    @Published var dailyQuote: String = "오늘도 힘찬 하루 보내세요!"
    @Published var briefingText: String? = nil
    @Published var errorMessage: String? = nil
    
    // 브리핑 중복 실행 방지 플래그
    private var isBriefingInProgress = false
    
    init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    func loadAllData() {
        let today = Date()
        refreshData(for: today)
        if tokenCheckClient.isLoggedIn {
            fetchHomeInfo()
        }
    }
    
    func loadTasksForSpecificDate(date: Date) {
        refreshData(for: date)
        if tokenCheckClient.isLoggedIn {
            fetchTodoListFromServer(date: date)
        }
    }
    
    private func refreshData(for date: Date) {
        let entities = localService.fetchTodos(date: date)
        let mappedTasks = entities.map { $0.toTask() }
        
        self.tasks = mappedTasks
        
        let today = Date()
        if Calendar.current.isDate(date, inSameDayAs: today) {
            self.todayTasksList = mappedTasks
        } else {
            let todayEntities = localService.fetchTodos(date: today)
            self.todayTasksList = todayEntities.map { $0.toTask() }
        }
    }
    
    private func fetchTodoListFromServer(date: Date, completion: (() -> Void)? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        todoService.fetchTodoList(date: dateString) { [weak self] result in
            guard let self = self else {
                completion?()
                return
            }
            if case .success(let dtos) = result {
                self.localService.syncWithServerData(dtos: dtos, date: date)
                self.refreshData(for: date)
            } else {
                print("⚠️ 서버 동기화 실패 (오프라인 모드 등)")
            }
            completion?()
        }
    }
    
    private func fetchHomeInfo() {
        let todayString = apiDateFormatter.string(from: Date())
        homeService.fetchHomeData(today: todayString) { [weak self] result in
            if case .success(let data) = result {
                self?.dailyQuote = data.encouragement
                self?.missionStat = MissionStat(
                    consecutiveDays: data.missionRecord.consecutiveSuccessCnt,
                    monthlyAchievementRate: Double(data.missionRecord.missionSuccessRate) / 100.0
                )
            }
        }
    }
    
    // MARK: - Briefing Logic
    
    /// 미션 완료 후 브리핑 실행 (자동 감지용)
    func checkAndPlayBriefing() {
        guard AlarmKitManager.shared.shouldPlayBriefing else { return }
        executeBriefing(isAuto: true)
    }
    
    /// 수동으로 브리핑 실행 (버튼 클릭 등 어느 화면에서든 호출 가능)
    func playManualBriefing() {
        executeBriefing(isAuto: false)
    }
    
    private func executeBriefing(isAuto: Bool) {
        // 중복 실행 방지
        if isBriefingInProgress { return }
        isBriefingInProgress = true
        
        print("🎙️ [Briefing] 브리핑 로직 시작 (Auto: \(isAuto))")
        
        let playBriefing = { [weak self] in
            guard let self = self else { return }
            
            // ✨ [해결책 추가] 대본을 짜기 직전에 무조건 로컬 DB에서 최신 오늘 할 일 데이터를 다시 불러옵니다!
            // 이렇게 하면 로그아웃 상태이거나, 다른 뷰에서 할 일을 수정했더라도 무조건 최신 상태가 반영됩니다.
            self.refreshData(for: Date())
            
            // 데이터 로드 완료 후 플래그 해제 (자동일 경우에만)
            if isAuto {
                AlarmKitManager.shared.shouldPlayBriefing = false
            }
            self.isBriefingInProgress = false
            
            let tasksToRead = self.todayTasksList.filter { !$0.isCompleted }
            let count = tasksToRead.count
            
            var script = ""
            
            // 상황에 따른 멘트 분기
            if isAuto {
                script += "미션 성공을 축하합니다! "
            } else {
                script += "오늘의 할 일을 브리핑해드릴게요. "
            }
            
            if count == 0 {
                script += "오늘 등록된 할 일이 없습니다. 편안한 하루 보내세요."
            } else {
                script += "오늘 예정된 할 일은 총 \(count)개 입니다. "
                for (index, task) in tasksToRead.prefix(5).enumerated() {
                    let order = ["첫 번째", "두 번째", "세 번째", "네 번째", "다섯 번째"][index]
                    script += "\(order), \(task.title). "
                }
                if count > 5 { script += "그 외 \(count - 5)개의 할 일이 더 있습니다." }
                script += "오늘도 힘찬 하루 보내세요!"
            }
            
            TTSManager.shared.play(script)
        }
        
        // 서버 동기화 후 실행 (5초 타임아웃 적용)
        if tokenCheckClient.isLoggedIn {
            // 타임아웃을 위한 DispatchWorkItem (혹시 서버가 너무 느리면 로컬 데이터로 읽음)
            var isFinished = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if !isFinished {
                    isFinished = true
                    print("⚠️ 서버 응답 지연 -> 로컬 데이터로 브리핑 시작")
                    playBriefing()
                }
            }
            
            fetchTodoListFromServer(date: Date()) {
                if !isFinished {
                    isFinished = true
                    playBriefing()
                }
            }
        } else {
            // 로그아웃 상태일 경우 지연 없이 바로 실행 (위에서 추가한 refreshData 덕분에 최신 로컬 데이터가 반영됨)
            playBriefing()
        }
    }
    
    // MARK: - User Interactions
    // (기존 코드 유지: addTask, deleteTask, updateTask, toggleTask 등)
    
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

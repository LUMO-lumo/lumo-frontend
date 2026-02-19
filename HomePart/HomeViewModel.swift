//
//  HomeViewModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftUI
import Combine

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
    @Published var tasks: [Task] = []              // 선택된 날짜의 할 일
    @Published var todayTasksList: [Task] = []      // 오늘 날짜의 할 일 (브리핑/미리보기용)
    @Published var missionStat = MissionStat(consecutiveDays: 0, monthlyAchievementRate: 0)
    @Published var dailyQuote: String = "오늘도 힘찬 하루 보내세요!"
    @Published var briefingText: String? = nil
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private var isBriefingInProgress = false
    
    // MARK: - Init
    init() {
        loadAllData()
    }
    
    // MARK: - Data Loading & Sync
    
    /// 앱 시작 시 전체 데이터 로드
    func loadAllData() {
        let today = Date()
        refreshData(for: today)
        if tokenCheckClient.isLoggedIn {
            fetchHomeInfo()
        }
    }
    
    /// 특정 날짜의 할 일 로드 (서버 동기화 포함)
    func loadTasksForSpecificDate(date: Date) {
        refreshData(for: date)
        if tokenCheckClient.isLoggedIn {
            fetchTodoListFromServer(date: date)
        }
    }
    
    /// 로컬 DB에서 데이터를 읽어와 Published 변수 갱신
    private func refreshData(for date: Date) {
        let entities = localService.fetchTodos(date: date)
        let mappedTasks = entities.map { $0.toTask() }
        
        self.tasks = mappedTasks
        
        // 오늘 날짜인 경우 메인 리스트도 함께 업데이트
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            self.todayTasksList = mappedTasks
        } else {
            let todayEntities = localService.fetchTodos(date: Date())
            self.todayTasksList = todayEntities.map { $0.toTask() }
        }
    }
    
    // MARK: - Remote API Logic
    
    private func fetchTodoListFromServer(date: Date, completion: (() -> Void)? = nil) {
        let dateString = apiDateFormatter.string(from: date)
        
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
    
    /// 미션 완료 후 브리핑 실행 (자동)
    func checkAndPlayBriefing() {
        guard AlarmKitManager.shared.shouldPlayBriefing else { return }
        executeBriefing(isAuto: true)
    }
    
    /// 수동 브리핑 실행
    func playManualBriefing() {
        executeBriefing(isAuto: false)
    }
    
    private func executeBriefing(isAuto: Bool) {
        guard !isBriefingInProgress else { return }
        isBriefingInProgress = true
        
        print("🎙️ [Briefing] 브리핑 로직 시작 (Auto: \(isAuto))")
        
        let playBriefing = { [weak self] in
            guard let self = self else { return }
            
            if isAuto { AlarmKitManager.shared.shouldPlayBriefing = false }
            self.isBriefingInProgress = false
            
            let tasksToRead = self.todayTasksList.filter { !$0.isCompleted }
            let count = tasksToRead.count
            
            var script = isAuto ? "미션 성공을 축하합니다! " : "오늘의 할 일을 브리핑해드릴게요. "
            
            if count == 0 {
                script += "오늘 등록된 할 일이 없습니다. 편안한 하루 보내세요."
            } else {
                script += "오늘 예정된 할 일은 총 \(count)개 입니다. "
                let orders = ["첫 번째", "두 번째", "세 번째", "네 번째", "다섯 번째"]
                
                for (index, task) in tasksToRead.prefix(5).enumerated() {
                    script += "\(orders[index]), \(task.title). "
                }
                
                if count > 5 { script += "그 외 \(count - 5)개의 할 일이 더 있습니다." }
                script += "오늘도 힘찬 하루 보내세요!"
            }
            
            TTSManager.shared.play(script)
        }
        
        // 서버 동기화 시도 (최대 3초 대기)
        if tokenCheckClient.isLoggedIn {
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
            playBriefing()
        }
    }
    
    // MARK: - Task Operations
    
    func addTask(title: String, date: Date) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newEntity = localService.addTodo(title: trimmedTitle, date: date)
        refreshData(for: date)
        
        if tokenCheckClient.isLoggedIn {
            let dateString = apiDateFormatter.string(from: date)
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
            let dateString = apiDateFormatter.string(from: taskDate)
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
    
    /// 메인 화면 미리보기용 (최대 3개)
    var previewTasks: [Task] {
        Array(todayTasksList.prefix(3))
    }
}

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
    // MARK: - Published Properties
    @Published var tasks: [Task] = []
    @Published var missionStat: MissionStat = MissionStat(consecutiveDays: 0, monthlyAchievementRate: 0)
    
    // [수정] homeSubtitle 제거 (HomeView에서 직접 텍스트로 관리)
    
    // [유지] 서버에서 받아올 오늘의 명언 문구 (사용자 요청에 따라 이 부분은 동적으로 유지)
    @Published var dailyQuote: String = "당신의 영향력의 한계는\n상상력입니다!"
    
    init() {
        loadInitialData()
    }
    
    // MARK: - 데이터 로드 (추후 API 연결)
    private func loadInitialData() {
        self.tasks = [
            Task(title: "일반쓰레기 버리기", isCompleted: false, date: Date()),
            Task(title: "과제 제출하기", isCompleted: false, date: Date()),
            Task(title: "공복 유산소하기", isCompleted: false, date: Date()),
            Task(title: "일기 쓰기", isCompleted: false, date: Date()),
            Task(title: "영양제 챙겨먹기", isCompleted: false, date: Date())
        ]
        
        // 통계 더미 데이터
        self.missionStat = MissionStat(consecutiveDays: 5, monthlyAchievementRate: 0.94)
    }
    
    // MARK: - 인터랙션 메서드
    func addTask(title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let newTask = Task(title: trimmedTitle, isCompleted: false, date: Date())
        tasks.append(newTask)
    }
    
    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
    }
    
    func deleteTask(at offsets: IndexSet) {
        offsets.map { tasks[$0].id }.forEach { deleteTask(id: $0) }
    }
    
    func toggleTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    // MARK: - 필터링 로직
    var todayTasks: [Task] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDate($0.date, inSameDayAs: Date()) }
    }
    
    var previewTasks: [Task] {
        return Array(todayTasks.prefix(3))
    }
}

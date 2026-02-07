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
    
    // 초기화
    init() {
        loadInitialData()
    }
    
    // MARK: - 더미 데이터 사용
    private func loadInitialData() {
        // 기존 HomeView의 더미 데이터와 동일한 구성으로 초기화
        self.tasks = [
            Task(title: "일반쓰레기 버리기", isCompleted: false, date: Date()),
            Task(title: "과제 제출하기", isCompleted: false, date: Date()),
            Task(title: "공복 유산소하기", isCompleted: false, date: Date()),
            Task(title: "일기 쓰기", isCompleted: false, date: Date()),
            Task(title: "영양제 챙겨먹기", isCompleted: false, date: Date())
        ]
        
        // 통계 더미 데이터
        // 추후에 연결할 예정
        self.missionStat = MissionStat(consecutiveDays: 5, monthlyAchievementRate: 0.94)
    }
    
    // MARK: - 추후에 서버하고 각각의 메서드와 연결할 예정
    
    // 할 일 추가
    func addTask(title: String) {
        let newTask = Task(title: title, isCompleted: false, date: Date())
        tasks.append(newTask)
    }
    
    // 할 일 삭제
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
    
    // 할 일 완료 상태 토글 (추후 체크박스 기능 구현 시 사용)
    func toggleTask(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    // 홈 화면 미리보기용 (상위 3개)
    var previewTasks: [Task] {
        return Array(tasks.prefix(3))
    }
}

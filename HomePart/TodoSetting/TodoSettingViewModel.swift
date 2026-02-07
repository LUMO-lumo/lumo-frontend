//
//  TodoSettingViewModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftUI
import Combine

class TodoSettingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var targetDate: Date = Date()
    @Published var selectedDay: String = String(Calendar.current.component(.day, from: Date()))
    @Published var editingTaskId: UUID? = nil
    @Published var isCreatingNewTask: Bool = false
    @Published var newTaskTitle: String = ""
    // UI에서 개별적으로 관리할 리스트 (필요 시 HomeViewModel과 연동 가능)
    // 모듈명 충돌을 피하기 위해 Task를 사용하는 경우를 대비
    @Published var localTasks: [Task] = []
    
    private let calendar = Calendar.current
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    // MARK: - Computed Properties
    var calendarDays: [String] {
        guard let range = calendar.range(of: .day, in: .month, for: targetDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetDate)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let paddingDays = firstWeekday - 1
        var daysArray = Array(repeating: "", count: paddingDays)
        for day in range { daysArray.append(String(day)) }
        return daysArray
    }
    
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: targetDate)
    }
    
    // MARK: - Methods
    func selectDay(_ day: String) {
        selectedDay = day
    }
    
    func startCreatingTask() {
        editingTaskId = nil
        newTaskTitle = ""
        isCreatingNewTask = true
    }
    
    func cancelNewTask() {
        isCreatingNewTask = false
        newTaskTitle = ""
    }
    
    // [추가됨] View에서 호출하는 addTask 메서드 구현
    func addTask(completion: (String) -> Void) {
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        completion(newTaskTitle)
        cancelNewTask()
    }
}

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
    @Published var targetDate: Date = Date()
    @Published var selectedDay: String = String(Calendar.current.component(.day, from: Date()))
    @Published var editingTaskId: UUID? = nil
    @Published var isCreatingNewTask: Bool = false
    @Published var newTaskTitle: String = ""
    
    private let calendar = Calendar.current
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    // [추가] 달력에서 선택된 (연/월/일)을 합쳐서 실제 Date 객체를 만들어내는 변수
    var resolvedSelectedDate: Date {
        var components = calendar.dateComponents([.year, .month], from: targetDate)
        components.day = Int(selectedDay) ?? 1
        return calendar.date(from: components) ?? Date()
    }
    
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
    
    func handleTaskSubmission() -> String? {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        cancelNewTask()
        return trimmed
    }
}

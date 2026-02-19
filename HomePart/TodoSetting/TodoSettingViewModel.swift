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
    
    // MARK: - Private Properties
    
    private let calendar = Calendar.current
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    // MARK: - Computed Properties
    
    /// 현재 선택된 (연/월/일)을 결합한 Date 객체
    var resolvedSelectedDate: Date {
        var components = calendar.dateComponents([.year, .month], from: targetDate)
        components.day = Int(selectedDay) ?? 1
        return calendar.date(from: components) ?? Date()
    }
    
    /// 달력 그리드에 표시될 일자 배열 (공백 포함)
    var calendarDays: [String] {
        guard let range = calendar.range(of: .day, in: .month, for: targetDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetDate)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let paddingDays = firstWeekday - 1
        
        var daysArray = Array(repeating: "", count: paddingDays)
        for day in range {
            daysArray.append(String(day))
        }
        return daysArray
    }
    
    /// 상단에 표시될 "yyyy년 M월" 형식의 타이틀
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: targetDate)
    }
    
    // MARK: - Public Methods
    
    /// 날짜 선택
    func selectDay(_ day: String) {
        selectedDay = day
    }
    
    /// 새 할 일 작성 모드 시작
    func startCreatingTask() {
        editingTaskId = nil
        newTaskTitle = ""
        isCreatingNewTask = true
    }
    
    /// 할 일 작성 취소
    func cancelNewTask() {
        isCreatingNewTask = false
        newTaskTitle = ""
    }
    
    /// 할 일 제출 처리 (유효성 검사 후 제목 반환)
    func handleTaskSubmission() -> String? {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        cancelNewTask()
        return trimmed
    }
}

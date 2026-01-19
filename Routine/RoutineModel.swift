//
//  RoutineModel.swift
//  Lumo
//
//  Created by 김승겸 on 1/19/26.
//

import Foundation
import SwiftData

// 고정된 루틴 타입
enum RoutineType: String, Codable, CaseIterable {
    case daily = "DAILY"
    case exam = "EXAM"
    case week = "WEEK"
    
    var typeName: String {
        switch self {
        case .daily: return "데일리"
        case .exam: return "시험기간"
        case .week: return "이번 주"
        }
    }
}


// 데일리 루틴 (예: 아침 스트레칭)
@Model
class RoutineTask {
    var id : UUID
    var type: RoutineType           // 데일리 / 시험기간 / 이번 주
    var title: String               // [필수] 루틴 이름
    var detail: String?             // [선택] 간단 설명
    
    var currentStreak: Int          // 연속 달성 횟수
    var isCompleted: Bool           // 오늘 완료 여부 (체크 여부)
    var lastCompletedDate: Date?    // 마지막으로 완료 버튼을 누른 날짜 (날짜 비교용)
    
    init(type: RoutineType, title: String, detail: String? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.detail = detail
        
        self.currentStreak = 0
        self.isCompleted = false
        self.lastCompletedDate = nil
    }
}

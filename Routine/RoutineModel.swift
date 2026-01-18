//
//  RoutineModel.swift
//  Lumo
//
//  Created by 김승겸 on 1/19/26.
//

import Foundation
import SwiftData

// 루틴 카테고리 (예: 데일리, 시험기간)
@Model
class RoutineCategory {
    var id: UUID
    var title: String   // 루틴 카테고리 이름
    
    // 카테고리(루틴)이 삭제되면 데일리 루틴도 삭제
    @Relationship(deleteRule: .cascade) var tasks: [RoutineTask]
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.tasks = []
        
    }
}


// 데일리 루틴 (예: 아침 스트레칭)
@Model
class RoutineTask {
    var id : UUID
    var title: String               // 루틴 이름
    var currentStreak: Int          // 연속 달성 횟수
    var isCompleted: Bool           // 오늘 완료 여부 (체크 여부)
    var lastCompletedDate: Date?    // 마지막으로 완료 버튼을 누른 날짜 (날짜 비교용)
    
    var category: RoutineCategory?
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.currentStreak = 0
        self.isCompleted = false
        self.lastCompletedDate = nil
    }
}

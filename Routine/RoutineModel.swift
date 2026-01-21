//
//  RoutineModel.swift
//  Lumo
//
//  Created by 김승겸 on 1/19/26.
//

import Foundation
import SwiftData

// 루틴 타입 (탭) : 추가/삭제 가능
@Model
class RoutineType {
    var id: UUID
    var title: String           // 카테고리 이름 (예: 데일리, 운동, 헬스 등)
    var createdAt: Date         // 생성일 (정렬용)
    
    // 이 카테고리에 포함된 할 일들 (Cascade: 카테고리 지우면 할 일도 다 지워짐)
    @Relationship(deleteRule: .cascade, inverse: \RoutineTask.category)
    var tasks: [RoutineTask]?
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.tasks = []
    }
}

// 데일리 루틴 (예: 아침 스트레칭)
@Model
class RoutineTask {
    var id : UUID
    var title: String               // [필수] 루틴 이름
    
    var category: RoutineType?
    
    var currentStreak: Int          // 연속 달성 횟수
    var isCompleted: Bool           // 오늘 완료 여부 (체크 여부)
    var lastCompletedDate: Date?    // 마지막으로 완료 버튼을 누른 날짜 (날짜 비교용)
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.currentStreak = 0
        self.isCompleted = false
        self.lastCompletedDate = nil
    }
}

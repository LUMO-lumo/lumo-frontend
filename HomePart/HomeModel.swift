//
//  HomeModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftData

// ==========================================
// MARK: - [Domain] 앱 내부 사용 모델 (View/Logic용)
// ==========================================

struct Task: Identifiable, Codable {
    var id: UUID = UUID()       // 앱 내부 고유 ID
    var apiId: Int?             // 서버 연동 시 ID 관리
    var title: String
    var isCompleted: Bool
    var date: Date
    
    // 날짜 포맷 헬퍼
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct MissionStat {
    var consecutiveDays: Int
    var monthlyAchievementRate: Double
    
    var ratePercentage: String {
        return "\(Int(monthlyAchievementRate * 100))%"
    }
}

// ==========================================
// MARK: - [Database] SwiftData 엔티티
// ==========================================

@Model
class TodoEntity {
    @Attribute(.unique) var id: UUID // 로컬 고유 ID
    var apiId: Int?                  // 서버 DB ID (nil이면 아직 서버 동기화 전)
    var title: String
    var isCompleted: Bool
    var date: Date
    var createdAt: Date              // 정렬용

    init(
        id: UUID = UUID(),
        apiId: Int? = nil,
        title: String,
        isCompleted: Bool = false,
        date: Date
    ) {
        self.id = id
        self.apiId = apiId
        self.title = title
        self.isCompleted = isCompleted
        self.date = date
        self.createdAt = Date()
    }
    
    /// Task 구조체로 변환하는 헬퍼 메서드
    func toTask() -> Task {
        return Task(
            id: self.id,
            apiId: self.apiId,
            title: self.title,
            isCompleted: self.isCompleted,
            date: self.date
        )
    }
}

// ==========================================
// MARK: - [Network] 서버 통신용 DTO (API 명세 기준)
// ==========================================

struct TodoDTO: Codable {
    let id: Int
    let content: String
    let eventDate: String // "yyyy-MM-dd"
}

struct HomeDTO: Codable {
    let encouragement: String
    let todo: [String]
    let missionRecord: MissionRecordDTO
}

struct MissionRecordDTO: Codable {
    let missionSuccessRate: Int
    let consecutiveSuccessCnt: Int
}

//
//  HomeModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation

// ==========================================
// MARK: - [Domain] 앱 내부 사용 모델 (View에서 사용)
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
// MARK: - [Network] 서버 통신용 DTO (명세서 기준)
// ==========================================

/// 1. Todo 관련 DTO
// 명세서: Get 일별 할 일 목록 조회 Result & Create/Update Result
struct TodoDTO: Codable {
    let id: Int
    let content: String
    let eventDate: String // "yyyy-MM-dd"
}

/// 2. Home 메인 화면 DTO
// 명세서: Get 홈 페이지 Result
struct HomeDTO: Codable {
    let encouragement: String
    let todo: [String]          // 명세서상 단순 문자열 리스트
    let missionRecord: MissionRecordDTO
}

struct MissionRecordDTO: Codable {
    let missionSuccessRate: Int
    let consecutiveSuccessCnt: Int
}

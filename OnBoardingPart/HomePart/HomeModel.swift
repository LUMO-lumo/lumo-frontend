//
//  HomeModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation
import SwiftUI
import Combine
import Moya

// MARK: - 할 일(Task) 데이터 모델
struct Task: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var date: Date // 할 일 날짜
}

// MARK: - 미션 통계(MissionStat) 데이터 모델
struct MissionStat {
    var consecutiveDays: Int // 연속 성공 일수
    var monthlyAchievementRate: Double // 월간 달성률 (0.0 ~ 1.0)
    
    // 달성률을 퍼센트 문자열로 반환 (예: 94%)
    var ratePercentage: String {
        return "\(Int(monthlyAchievementRate * 100))%"
    }
}

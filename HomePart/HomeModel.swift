//
//  HomeModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation

// MARK: - 할 일(Task) 데이터 모델
struct Task: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
    var date: Date
}

// MARK: - 미션 통계 데이터 모델
struct MissionStat {
    var consecutiveDays: Int
    var monthlyAchievementRate: Double
    
    var ratePercentage: String {
        return "\(Int(monthlyAchievementRate * 100))%"
    }
}

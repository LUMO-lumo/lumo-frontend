//
//  NoticeModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/14/26.
//

import Foundation

struct NoticeResponse: Decodable {
    let code: String
    let message: String
    let result: [Notice] // 리스트이므로 배열
    let success: Bool
}

struct NoticeDetailResponse: Decodable {
    let code: String
    let message: String
    let result: Notice // 배열 []이 아니라 객체 {} 임에 주의!
    let success: Bool
}

// 기존 Notice 모델 업데이트
struct Notice: Codable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let content: String? // 목록 조회시엔 없을 수 있으므로 옵셔널 처리
    let createdAt: String
    let updatedAt: String? // 상세 조회에만 있는 경우를 대비해 옵셔널
    
    // 날짜 포맷팅 (UI용)
    var formattedDate: String {
        guard let date = ISO8601DateFormatter().date(from: createdAt) else {
            return createdAt.prefix(10).description // 파싱 실패시 앞 10자리만
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd" // 예: 2026.01.28
        return formatter.string(from: date)
    }
}

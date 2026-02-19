//
//  AlarmChangeModel.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/3/26.
//

import SwiftUI
import Foundation
import Combine
import AlarmKit
import Moya


// AlarmChange 화면에서 사용하는 특정 데이터나 상수를 정의합니다.
struct AlarmChangeModel {
    // 미션 목록 데이터 (Title, ImageName)
    static let missions: [(title: String, imageName: String)] = [
        ("수학문제", "MathMission"),
        ("OX 퀴즈", "OXMission"),
        ("따라쓰기", "WriteMission"),
        ("거리미션", "DestMission")
    ]
    
    // 요일 표시 텍스트
    static let days: [String] = ["월", "화", "수", "목", "금", "토", "일"]
}

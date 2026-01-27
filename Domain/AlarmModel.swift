//
//  AlarmModel.swift
//  Lumo
//
//  Created by 김승겸 on 1/3/26.
//

import Foundation
import SwiftData

@Model
class AlarmModel: Identifiable {
    // 고유 식별자 검색 속도 향상 및 중복 방지
    @Attribute(.unique) var id: UUID
    
    var time: Date // 알람 시간
    var label: String // 알람 레이블
    
    // 사운드 관련
    var soundName: String // 벨소리명
    var soundVolume: Double // 벨소리 크기
    
    // 대용량 이미지 데이터는 별도 파일로 관리하여 앱 속도 저하 방지
    @Attribute(.externalStorage) var backgroundImageData: Data?
    
    // 미션 관련
    var missionType: String   // "math", "typing", "distance", "ox"
    var missionTarget: String // "auto", "할 수 있다!", "100", "common_sense" 등
    var isEnabled: Bool
    
    init(
        time: Date,
        label: String = "1교시 있는 날",
        soundName: String = "커피한잔의 여유",
        soundVolume: Double = 0.5,
        missionType: String = "math",
        missionTarget: String = "auto"
    ) {
        self.id = UUID()
        self.time = time
        self.label = label
        self.soundName = soundName
        self.soundVolume = soundVolume
        self.missionType = missionType
        self.missionTarget = missionTarget
        self.isEnabled = true
    }
}

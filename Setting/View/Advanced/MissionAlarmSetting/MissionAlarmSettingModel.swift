//
//  MissionAlarmSettingModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation

struct MissionAlarmSettingRequest: Codable {
    var theme: String = "LIGHT"
    var language: String = "KO"
    var batterySaving: Bool = true
    var alarmOffMissionDefaultType: String = "MATH"
    var alarmOffMissionDefaultLevel: String = "LOW"
    var alarmOffMissionDefaultDuration: Int 
    var briefingSentence: String = ""
    var briefingVoiceDefaultType: String = "WOMAN"
}

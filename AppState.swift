//
//  AppState.swift
//  Lumo
//
//  Created by 김승겸 on 2/12/26.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    // 앱이 보여줄 수 있는 루트 화면의 종류
    enum RootView: Equatable {
        case onboarding     // 온보딩
        case main           // 메인 화면
        case mathMission(alarmId: Int, label: String) // 수학 미션 화면
        case distanceMission(alarmId: Int) // 거리 미션 화면 (필요 시 사용)
        case oxMission(alarmId: Int)
    }
    
    @Published var currentRoot: RootView
    
    init() {
        // 앱이 켜질 때 UserDefaults를 확인해서 초기 화면 결정
        let isFinished = UserDefaults.standard.bool(forKey: "isOnboardingFinished")
        self.currentRoot = isFinished ? .main : .onboarding
    }
}

//
//  LumoApp.swift
//  Lumo
//
//  Created by 김승겸 on 1/2/26.
//

import SwiftUI
import SwiftData

@main
struct LumoApp: App {
    // UserDefaults 연동
    @AppStorage("userTheme") private var userTheme: String = "System"
    @AppStorage("isOnboardingFinished") var isOnboardingFinished: Bool = false
    
    // ✅ 전역 상태 관리 객체 생성
    @StateObject private var appState = AppState()
    @State private var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                // ✅ appState에 따라 루트 화면 교체
                switch appState.currentRoot {
                case .onboarding:
                    // 기존 온보딩 로직
                    NavigationStack(path: $onboardingViewModel.path) {
                        OnBoardingView()
                            .navigationDestination(for: OnboardingStep.self) { step in
                                switch step {
                                case .initialSetup:
                                    InitialSetupContainerView()
                                case .introMission:
                                    MissionIntroView()
                                case .missionSelect:
                                    MissionContainerView()
                                case .home:
                                    // 온보딩 완료 시점
                                    Color.clear
                                        .onAppear {
                                            // 1. AppStorage 업데이트
                                            isOnboardingFinished = true
                                            // 2. AppState 업데이트 (화면 전환)
                                            withAnimation {
                                                appState.currentRoot = .main
                                            }
                                        }
                                }
                            }
                    }
                    
                    
                case .main:
                    MainView()
                    
                case .mathMission(let alarmId, let label):
                    // 수학 미션 화면 (네비게이션 없이 풀스크린 교체)
                    MathMissionView(alarmId: alarmId, alarmLabel: label)
                    
                case .distanceMission(let alarmId):
                    // 거리 미션 화면
                    DistanceMissionView(alarmId: alarmId)
                    
                case .oxMission(let alarmID):
                    OXMissionView(alarmId: alarmID)
                }
            }
            .environment(onboardingViewModel)
            .environmentObject(appState)
            .preferredColorScheme(selectedScheme)
            // isOnboardingFinished 값이 외부(설정 등)에서 바뀌었을 때 싱크 맞추기
            .onChange(of: isOnboardingFinished) { _, newValue in
                if newValue && appState.currentRoot == .onboarding {
                    appState.currentRoot = .main
                } else if !newValue {
                    appState.currentRoot = .onboarding
                }
            }
        }
        .modelContainer(for: [UserModel.self, RoutineType.self, RoutineTask.self])
    }
    
    var selectedScheme: ColorScheme? {
        switch userTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }
}

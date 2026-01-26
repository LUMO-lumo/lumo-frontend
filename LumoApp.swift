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
    @AppStorage("isOnboardingFinished") var isOnboardingFinished: Bool = false
    @State private var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboardingFinished {
                    MainView()
                } else {
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
                                    Color.clear
                                        .onAppear {
                                            isOnboardingFinished = true
                                        }
                                }
                            }
                    }
                }
            }
            .environment(onboardingViewModel)
        }
        .modelContainer(for: [UserModel.self, RoutineType.self, RoutineTask.self])
    }
}

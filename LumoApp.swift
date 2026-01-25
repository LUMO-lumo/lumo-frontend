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
    @State private var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
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
                            
                        default:
                            EmptyView()
                        }
                    }
            }
            .environment(onboardingViewModel)
        }
        .modelContainer(for: UserModel.self)
    }
}

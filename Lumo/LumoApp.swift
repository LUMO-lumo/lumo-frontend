//
//  LumoApp.swift
//  Lumo
//
//  Created by 김승겸 on 1/2/26.
//

import SwiftUI

@main
struct LumoApp: App {
    @State private var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            MissionSelectView().environment(onboardingViewModel)
        }
    }
}

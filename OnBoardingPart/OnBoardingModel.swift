//
//  OnBoardingModel.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import Foundation

struct OnboardingItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

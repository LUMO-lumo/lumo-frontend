//
//  NotificationSettingVIew.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

import SwiftUI

struct NotificationSettingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            
            Text("기기 알림 설정 허용")
                .font(.Subtitle1)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NotificationSettingView(currentPage: .constant(2))
        .environment(OnboardingViewModel())
}

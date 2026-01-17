//
//  TimeSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/2/26.
//

// 깃헙 연동 테스트

import SwiftUI

struct AlarmSettingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            
            Text("알람 설정")
                .font(.Subtitle1)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    AlarmSettingView(currentPage: .constant(1))
        .environment(OnboardingViewModel())
}

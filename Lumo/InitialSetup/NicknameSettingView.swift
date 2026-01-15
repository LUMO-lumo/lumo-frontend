//
//  NicknameSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

//
//  BackgroundSelectView.swift
//  Lumo
//
//  Created by 김승겸 on 1/13/26.
//

import SwiftUI

struct NicknameSettingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            
            Text("닉네임 설정")
                .font(.Subtitle1)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

#Preview {
    NicknameSettingView(currentPage: .constant(0))
        .environment(OnboardingViewModel())
}

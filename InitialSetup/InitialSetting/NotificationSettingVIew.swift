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
            
            Text("기기의 알림 설정을 허용해주세요.")
                .font(.Subtitle1)
                .foregroundStyle(Color.black)
            
            Spacer() .frame(height: 8)
            
            Text("알람이 울리려면 꼭 필요해요!")
                .font(.Body1)
                .foregroundStyle(Color(hex: "7A7F88"))
            
            Spacer()
            
            Image("MissionClap")
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NotificationSettingView(currentPage: .constant(2))
        .environment(OnboardingViewModel())
}

//
//  MissionIntroView.swift
//  Lumo
//
//  Created by 김승겸 on 1/13/26.
//

import SwiftUI

struct MissionIntroView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            // 기본 텍스트 색상 (.primary) 사용 시 다크모드 자동 대응됨
            Text("이제 미션을 설정해볼까요?")
                .font(.custom("Pretendard-Bold", size: 24))
                .foregroundStyle(.primary)
            
            Spacer() .frame(height: 82)
            
            Image("MissionClap")
            
            Spacer()
            
            Button(action: {
                viewModel.path.append(OnboardingStep.missionSelect)
            }) {
                Text("다음")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color(hex: "404347"))
                    .background(Color(hex: "DDE1E8"))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MissionIntroView()
        .environment(OnboardingViewModel())
}

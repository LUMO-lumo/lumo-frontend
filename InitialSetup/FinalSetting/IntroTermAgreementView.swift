//
//  IntroTermAgreementView.swift
//  Lumo
//
//  Created by 김승겸 on 1/26/26.
//

import SwiftUI

struct IntroTermAgreementView: View {
    // iOS 17+ Observation 프레임워크 사용 시 (Observable 매크로)
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("IntroTermAgreementView")
            
            Spacer()
            
            Button(action: {
                viewModel.path.append(OnboardingStep.home)
            }) {
                Text("시작하기")
                    
                    .font(.Subtitle3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.white)
                    .background(Color(hex: "F55641"))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
        }
        // 네비게이션 바 뒤로가기 버튼 숨김은 보통 최상위 컨테이너(VStack)에 겁니다.
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    IntroTermAgreementView(currentPage: .constant(3))
        .environment(OnboardingViewModel())
}

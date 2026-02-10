//
//  MissionContainerView.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

import SwiftUI

struct MissionContainerView: View {
    @State private var currentPage = 0
    @Environment(OnboardingViewModel.self) var viewModel
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    Rectangle()
                    // 현재 페이지면 주황색, 아니면 회색
                        .foregroundStyle(index <= currentPage ? Color(hex: "F55641") : Color(hex: "DDE1E8"))
                        .frame(height: 3)
                        .cornerRadius(999)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            
            // 2. 화면들 (TabView)
            TabView(selection: $currentPage) {
                // 첫 번째: 미션 선택
                MissionSelectView(currentPage: $currentPage)
                    .tag(0)
                
                // 두 번째: 미션 미리보기
                MissionPreviewView(currentPage: $currentPage)
                    .tag(1)
                
                FinalCheckView(currentPage: $currentPage)
                    .tag(2)
                
                IntroTermAgreementView(currentPage: $currentPage)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage) // 슬라이드 애니메이션
            
            // (참고: 버튼은 각 화면의 기능이 달라서 자식 뷰 내부에 두는 것이 좋습니다)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MissionContainerView()
        .environment(OnboardingViewModel())
}

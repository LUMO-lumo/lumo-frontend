//
//  MissionPreviewView.swift
//  Lumo
//
//  Created by 김승겸 on 1/6/26.
//

import SwiftUI

struct MissionPreviewView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    @Environment(\.colorScheme) var colorScheme // 다크모드 감지
    
    var body: some View {
        VStack {
            
            switch viewModel.selectedMission {
            case .math:
                MathMissionExView()
            case .typing:
                TypingMissionExView()
            case .distance:
                DistanceMissionExView()
            case .ox:
                OxMissionExView()
            }
            
            // 이전 및 다음 버튼
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation {
                        currentPage = 0
                    }
                }) {
                    Text("이전")
                        .font(.system(size: 20, weight: .bold)) // .Subtitle3 대체
                        // 다크모드: 흰색 글씨, 라이트모드: 진회색 글씨
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "404347"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        // 다크모드: 투명 배경, 라이트모드: 흰색 배경
                        .background(colorScheme == .dark ? Color.clear : Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
                        )
                }
                
                Button(action: {
                    withAnimation {
                        currentPage = 2
                    }
                }) {
                    Text("다음")
                        .font(.system(size: 20, weight: .bold)) // .Subtitle3 대체
                        // 배경이 밝은 회색(DDE1E8)이므로, 다크모드에서도 어두운 글씨가 잘 보임
                        // 가독성을 위해 검은색 계열 유지
                        .foregroundStyle(Color(hex: "404347"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "DDE1E8"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
                        )
                    
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MissionPreviewView(currentPage: .constant(1))
        .environment(OnboardingViewModel())
}

//
//  FinalCheckView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalCheckView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .foregroundStyle(Color(hex: "979DA7"))
                        .frame(height: 3)
                        .cornerRadius(999)
                }
            }
            .padding(.vertical, 10)
            
            Spacer()
            
            Text("이렇게 알람이 울려요.\n알람을 설정하시겠어요?")
                .font(.Subtitle1)
            
            Spacer()
            
            VStack {
                Text("1교시 있는 날")
                    .font(.pretendardBold16)
                
                Text("06:55")
                    .font(.pretendardSemiBold54)
                    
                switch viewModel.selectedMission {
                case .math:
                    FinalMathView()
                case .typing:
                    FinalTypingView()
                case .distance:
                    FinalDistanceView()
                case .ox:
                    FinalOxView()
                }
                
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(310/506, contentMode: .fit)
            .padding(.horizontal, 28)
            .padding(.vertical, 44)
            .background(Color(hex: "C7C7C7"))
            .cornerRadius(12)
            .padding(.horizontal, 18)
            
            Spacer()
            
            
            // 이전 및 다음 버튼
            HStack(spacing: 10) {
                Button(action: {
                    viewModel.path.removeLast()
                }) {
                    Text("이전")
                        .font(.Subtitle3)
                        .foregroundStyle(Color(hex: "404347"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .backgroundStyle(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
                        )
                }
                
                Button(action: {
                    viewModel.path.append(OnboardingStep.finalComplete)
                }) {
                    Text("다음")
                        .font(.Subtitle3)
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
    FinalCheckView().environment(OnboardingViewModel())
}

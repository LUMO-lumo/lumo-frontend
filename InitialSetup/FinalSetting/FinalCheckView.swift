//
//  FinalCheckView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalCheckView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Environment(\.colorScheme) var scheme // 다크 모드 감지
    @Binding var currentPage: Int
    
    var body: some View {
        ZStack {
            // 전체 배경
            (scheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                
                Spacer()
                
                Text("이렇게 알람이 울려요.\n알람을 설정하시겠어요?")
                    .font(.Subtitle1)
                    .foregroundStyle(scheme == .dark ? .white : .black)
                
                Spacer()
                
                VStack {
                    Text("1교시 있는 날")
                        .font(.pretendardBold16)
                        .foregroundStyle(scheme == .dark ? .white : .black)
                    
                    Text("06:55")
                        .font(.pretendardSemiBold54)
                        .foregroundStyle(scheme == .dark ? .white : .black)
                        
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
                // 미리보기 카드 배경: 다크모드 대응
                .background(scheme == .dark ? Color(uiColor: .systemGray6) : Color(hex: "C7C7C7"))
                .cornerRadius(12)
                .padding(.horizontal, 18)
                
                Spacer()
                
                // 이전 및 다음 버튼
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation {
                            currentPage = 1
                        }
                    }) {
                        Text("이전")
                            .font(.Subtitle3)
                            .foregroundStyle(scheme == .dark ? .white : Color(hex: "404347"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .backgroundStyle(scheme == .dark ? Color.black : Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(scheme == .dark ? Color.gray600 : Color(hex: "DDE1E8"), lineWidth: 2)
                            )
                    }
                    
                    Button(action: {
                        withAnimation {
                            currentPage = 3
                        }
                    }) {
                        Text("시작하기")
                            .font(.Subtitle3)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "F55641"))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    FinalCheckView(currentPage: .constant(2))
        .environment(OnboardingViewModel())
}

//
//  InitialSetupContainerView.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

import SwiftUI
import SwiftData

struct InitialSetupContainerView: View {
    @State private var currentPage = 0
    @Environment(OnboardingViewModel.self) var viewModel
    
    @Environment(\.modelContext) private var modelContext
    @Query private var userModel: [UserModel]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. 상단 프로그레스 바 (이전 단계에서 만든 것)
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .foregroundStyle(index <= currentPage ? Color(hex: "F55641") : Color(hex: "DDE1E8"))
                        .frame(height: 3)
                        .cornerRadius(999)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 10)
            
            Spacer()
            
            // 2. 화면들 (TabView)
            TabView(selection: $currentPage) {
                NicknameSettingView(currentPage: $currentPage)
                    .tag(0)
                AlarmSettingView(currentPage: $currentPage)
                    .tag(1)
                NotificationSettingView(currentPage: $currentPage)
                    .tag(2)
                LocationSettingView(currentPage: $currentPage)
                    .tag(3)
                BackgroundSelectView(currentPage: $currentPage)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage) // 슬라이드 효과
            
            VStack {
                if currentPage <= 1 {
                    Button(action: {
                        
                        if currentPage == 0 {
                            saveNickname()
                        }
                        
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Text("다음")
                            .font(.Subtitle3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Color(hex: "404347"))
                            .background(Color(hex: "DDE1E8"))
                            .cornerRadius(8)
                    }
                } else {
                    HStack(spacing: 10) {
                        // 이전 버튼
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
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
                        
                        // 다음 버튼
                        Button(action: {
                            if currentPage == 4 {
                                viewModel.path.append(OnboardingStep.introMission)
                            } else {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        }) {
                            Text("다음")
                                .font(.Subtitle3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(Color(hex: "404347"))
                                .background(Color(hex: "DDE1E8"))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.bottom, 10)     // 바닥 여백
        }
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
    }
    
    private func saveNickname() {
        if let existingUser = userModel.first {
            // 기존 데이터 수정
            existingUser.nickname = viewModel.nickname
        } else {
            // 새 데이터 생성
            let newUser = UserModel(nickname: viewModel.nickname)
            modelContext.insert(newUser)
        }
        
        print("닉네임 저장 완료: \(viewModel.nickname)")
    }
}

#Preview {
    InitialSetupContainerView()
        .environment(OnboardingViewModel())
}

//
//  InitialSetupContainerView.swift
//  Lumo
//
//  Created by User on 2/19/26.
//

import SwiftUI
import SwiftData

struct InitialSetupContainerView: View {
    @State private var currentPage = 0
    @Environment(OnboardingViewModel.self) var viewModel
    @Environment(\.colorScheme) var scheme // 다크 모드 감지
    
    var body: some View {
        ZStack {
            // 전체 배경색 설정
            (scheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 1. 상단 프로그레스 바
                HStack(spacing: 6) {
                    ForEach(0..<5) { index in
                        Rectangle()
                            .foregroundStyle(index <= currentPage ? Color(hex: "F55641") : (scheme == .dark ? Color.gray.opacity(0.3) : Color(hex: "DDE1E8")))
                            .frame(height: 3)
                            .cornerRadius(999)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                Spacer()
                
                // 2. 화면들 (TabView 방식 유지)
                TabView(selection: $currentPage) {
                    // 닉네임 설정 (Page 0)
                    NicknameSettingView(currentPage: $currentPage)
                        .tag(0)
                    
                    // [중요] 기존 AlarmSettingView 대신 새로 만든 뷰로 교체
                    OnboardingAlarmSetupView(currentPage: $currentPage)
                        .tag(1)
                    
                    // 알림 권한 설정 (Page 2)
                    NotificationSettingView(currentPage: $currentPage)
                        .tag(2)
                    
                    // 위치 권한 설정 (Page 3)
                    LocationSettingView(currentPage: $currentPage)
                        .tag(3)
                    
                    // 배경화면 선택 (Page 4)
                    BackgroundSelectView(currentPage: $currentPage)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // 스와이프 제스처 충돌 방지를 위해 드래그 제스처를 뷰가 가져가도록 설정 (선택사항)
                .gesture(DragGesture().onEnded { _ in })
                
                // 3. 하단 네비게이션 컨트롤 영역
                VStack {
                    if currentPage <= 1 {
                        // 0, 1페이지: '다음' 버튼 하나만 표시
                        Button(action: {
                            if currentPage == 0 {
                                saveNickname()
                            }
                            nextPage()
                        }) {
                            Text("다음")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(scheme == .dark ? .white : Color(hex: "404347"))
                                .background(scheme == .dark ? Color.gray.opacity(0.3) : Color(hex: "DDE1E8"))
                                .cornerRadius(8)
                        }
                    } else {
                        // 2~4페이지: '이전', '다음' 버튼 표시
                        HStack(spacing: 10) {
                            Button(action: {
                                prevPage()
                            }) {
                                Text("이전")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(scheme == .dark ? .white : Color(hex: "404347"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(scheme == .dark ? Color.black : Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(scheme == .dark ? Color.gray.opacity(0.5) : Color(hex: "DDE1E8"), lineWidth: 2)
                                    )
                            }
                            
                            Button(action: {
                                if currentPage == 4 {
                                    // 마지막 단계에서 메인 미션 화면으로 이동
                                    viewModel.path.append(OnboardingStep.introMission)
                                } else {
                                    nextPage()
                                }
                            }) {
                                Text("다음")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .foregroundStyle(scheme == .dark ? .white : Color(hex: "404347"))
                                    .background(scheme == .dark ? Color.gray.opacity(0.3) : Color(hex: "DDE1E8"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 24)
            .navigationBarBackButtonHidden(true) // 온보딩으로 되돌아가는 시스템 제스처 방지
        }
    }
    
    // MARK: - Helper Methods
    
    private func nextPage() {
        // [중요] 키보드 닫기: 텍스트 입력 후 바로 '다음'을 누를 때 튕김 현상 방지
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        withAnimation(.easeInOut) {
            currentPage += 1
        }
    }
    
    private func prevPage() {
        withAnimation(.easeInOut) {
            currentPage -= 1
        }
    }
    
    private func saveNickname() {
        // 닉네임 저장 로직 (UserDefaults 사용)
        UserDefaults.standard.set(viewModel.nickname, forKey: "tempNickname")
        print("📝 닉네임 저장됨: \(viewModel.nickname)")
    }
}

// MARK: - Preview
#Preview {
    InitialSetupContainerView()
        .environment(OnboardingViewModel())
}

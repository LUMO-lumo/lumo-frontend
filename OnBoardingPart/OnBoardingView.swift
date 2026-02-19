//
//  OnBoardingView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import SwiftUI

struct OnBoardingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @State private var PageNumber = 0

    let coralOrange = Color(hex: "F55641")
    let corallightGray = Color(hex: "DDE1E8")
    let coradeepGray = Color(hex: "979DA7")

    
    var body: some View {
        ZStack {
            // 다크모드 대응을 위해 기본 배경색을 명시적으로 지정하거나,
            // 시스템 기본 배경색을 따르게 둡니다. (기본은 자동)
            
            VStack {
                TabView(selection: $PageNumber) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        if index == 0 {
                            OnboardingFirstPageView(item: onboardingData[index])
                                .tag(index)
                        } else {
                            OnboardingPageView(item: onboardingData[index])
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                // 애니메이션 충돌 방지를 위해 .animation 제거 유지
                
                // 2. 하단 컨트롤 영역
                VStack(spacing: 16) {
                    HStack(spacing: 25) {
                        ForEach(1..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .frame(width: PageNumber == index ? 8 : 6, height: PageNumber == index ? 8 : 6)
                                .foregroundStyle(PageNumber == index ? Color(hex: "979DA7") : Color(hex: "DDE1E8"))
                                .animation(.spring(), value: PageNumber)
                        }
                    }
                    .padding(.bottom, 45)
                    .opacity(PageNumber == 0 ? 0 : 1)
                    .animation(.easeInOut, value: PageNumber)
                    
                    // 하단 버튼
                    Button(action: {
                        handleButtonTap()
                    }) {
                        Text(PageNumber == onboardingData.count - 1 ? "시작하기" : "다음")
                            .font(.system(size: 20, weight: .semibold))
                            // 버튼 배경이 밝은 회색(DDE1E8)이므로, 텍스트는 어두운 색 유지(.black.opacity(0.6))가 가독성에 좋습니다.
                            // 만약 버튼 배경도 다크모드에 따라 어두워진다면 이 부분도 수정해야 하지만,
                            // 현재 디자인(라이트 그레이 버튼)상 검은 글씨가 맞습니다.
                            .foregroundStyle(PageNumber == onboardingData.count - 1 ? .white : .black.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                PageNumber == onboardingData.count - 1
                                ? Color(hex: "F55641")
                                : Color(hex: "DDE1E8")
                            )
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private func handleButtonTap() {
        if PageNumber < onboardingData.count - 1 {
            withAnimation {
                PageNumber += 1
            }
        } else {
            viewModel.path.append(OnboardingStep.initialSetup)
        }
    }
}

// 3. 첫 번째 페이지 (LUMO 텍스트 포함)
struct OnboardingFirstPageView: View {
    let item: OnboardingItem
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 120)
                    .padding(.horizontal, 20)
                
                Text("LUMO")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "F55641"))
                    .tracking(2)
                
                VStack(spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        // [수정] .black -> .primary (다크모드 대응)
                        .foregroundStyle(.primary)
                    
                    Text(item.description)
                        .font(.system(size: 15))
                        // [수정] .gray -> .secondary (다크모드 대응 및 가독성 향상)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

// 4. 나머지 페이지
struct OnboardingPageView: View {
    let item: OnboardingItem
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 15) {
                
                VStack(spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        // [수정] .black -> .primary (다크모드 대응)
                        .foregroundStyle(.primary)
                    
                    Text(item.description)
                        .font(.system(size: 15))
                        // [수정] .gray -> .secondary (다크모드 대응)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                    
                }
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .padding(.horizontal, 20)
                
            }
            
            Spacer()
        }
        .padding(.top, 30)
    }
}


#Preview {
    OnBoardingView()
        .environment(OnboardingViewModel())
}

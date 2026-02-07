//
//  OnBoardingView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import SwiftUI

struct OnBoardingView: View {
    @State private var PageNumber = 0
    
    var body: some View {
        ZStack {
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
                .animation(.easeInOut, value: PageNumber)
                
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
                    // 첫 번째 페이지(PageNumber 0)일 때는 투명도를 0으로 만들어 숨깁니다.
                    .opacity(PageNumber == 0 ? 0 : 1)
                    .animation(.easeInOut, value: PageNumber)
                    
                    // 하단 버튼
                    Button(action: {
                        handleButtonTap()
                        
                        /// 첫화면으로 넘어가게 하는 화면으로 넘어가게 만들기
                        
                    }) {
                        Text(PageNumber == onboardingData.count - 1 ? "시작하기" : "다음")
                            .font(.system(size: 20, weight: .semibold))
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
    
//기능적으로 확인을 하는 부분
    private func handleButtonTap() {
        if PageNumber < onboardingData.count - 1 {
            withAnimation {
                PageNumber += 1
            }
        } else {
            print("온보딩 완료!")
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
                        .foregroundStyle(.black)
                    
                    Text(item.description)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
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
                        .foregroundStyle(.black)
                    
                    Text(item.description)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
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
}

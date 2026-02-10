//
//  Tabber.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import SwiftUI
import Foundation
import SwiftData
import PhotosUI


// MARK: - 앱의 시작점
struct MainView: View {
    // 현재 선택된 탭 (0: 홈, 1: 알람, 2: 루틴, 3: 설정)
    
    @Environment(OnboardingViewModel.self) var viewModel
    @State private var selectedTab = 0
    
    // 탭바 숨김 여부를 관리하는 변수
    @State private var isTabBarHidden: Bool = false
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    Text(" 알람 파트")
                case 2:
                    RoutineView(isTabBarHidden: $isTabBarHidden)
                case 3:
                    ProfileSettingView(isTabBarHidden: $isTabBarHidden)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            

          if !isTabBarHidden {
              CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard) // 키보드 올라올 때 탭바 찌그러짐 방지
    }
}

// MARK: - [디자인] 커스텀 탭바 컴포넌트
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    // 브랜드 컬러 (LUMO Pink/Red)
    let activeColor = Color(hex: "F55641")
    let inactiveColor = Color.gray.opacity(0.8)
    
    var body: some View {
        HStack {
            // 탭 1: 홈
            TabBarButton(
                icon: selectedTab == 0 ? "house.fill" : "house",
                text: "홈",
                isSelected: selectedTab == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor
            ) { selectedTab = 0 }
            
            Spacer()
            
            // 탭 2: 알람
            TabBarButton(
                icon: selectedTab == 1 ? "bell.fill" : "bell",
                text: "알람",
                isSelected: selectedTab == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor
            ) { selectedTab = 1 }
            
            Spacer()
            
            // 탭 3: 루틴
            TabBarButton(
                icon: "chart.xyaxis.line", // 루틴 아이콘
                text: "루틴",
                isSelected: selectedTab == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor
            ) { selectedTab = 2 }
            
            Spacer()
            
            // 탭 4: 설정
            TabBarButton(
                icon: selectedTab == 3 ? "gearshape.fill" : "gearshape",
                text: "설정",
                isSelected: selectedTab == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor
            ) { selectedTab = 3 }
        }
        .padding(.horizontal, 30) // 좌우 여백
        .padding(.top, 14) // 아이콘 위 여백
        .padding(.bottom, 10) // 아이콘 아래 여백 (SafeArea 고려 전)
        .background(Color.white) // 배경색 흰색
        // 상단 그림자 효과 (사진처럼 보이게)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
    }
}

// MARK: - 탭 버튼 디자인
struct TabBarButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let activeColor: Color
    let inactiveColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                
                Text(text)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .foregroundStyle(isSelected ? activeColor : inactiveColor)
            .frame(maxWidth: .infinity)
        }
    }
}


#Preview{
    MainView()
}


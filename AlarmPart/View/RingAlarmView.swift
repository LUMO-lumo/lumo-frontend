//
//  AlarmPlayingOverlay.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/15/26.
//

import Combine
import SwiftUI

import AlarmKit

struct AlarmPlayingOverlay: View {
    
    // 홈 화면 이동을 위해 AppState 연결
    @EnvironmentObject var appState: AppState
    
    @StateObject private var alarmManager = AlarmKitManager.shared
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {

            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // 미션 타입에 따라 실제 미션 뷰 연결
            if let missionType = alarmManager.triggeredMissionType, missionType != "NONE" {
                // alarmId가 있어야 API 호출 가능. 없으면(로컬/에러) 기본 화면.
                if let alarmId = alarmManager.triggeredAlarmId {
                    missionContent(
                        type: missionType,
                        id: alarmId,
                        label: alarmManager.triggeredAlarmLabel
                    )
                } else {
                    // ID가 없으면 그냥 기본 끄기 화면 보여주거나, 임시 ID로 진행
                    defaultAlarmView
                }
            } else {
                defaultAlarmView // 기본 알람 해제 화면
            }
        }
        .zIndex(9999)
        // [핵심 기능] 미션 완료 신호가 오면 홈으로 강제 이동
        .onChange(of: alarmManager.shouldPlayBriefing) { oldaValue, newValue in
            if newValue {
                print("🔄 [Overlay] 미션 완료 감지 -> 홈 화면으로 이동 요청")
                
                // 1. 미션 테스트 중이었다면 Root를 홈으로 복귀 (nil 또는 .home 등 프로젝트 규칙에 맞게 설정)
                // 만약 AppState의 Root 초기화 값이 nil이라면:
                // appState.currentRoot = nil
                
                // 2. 탭 뷰 구조라면 홈 탭으로 이동 (AppState에 selectedTab이 있다고 가정)
                // appState.selectedTab = .home
                
                // 🚨 사용자 프로젝트의 AppState 구조를 정확히 모르므로,
                // 이곳에서 '홈으로 가는 코드'를 확실하게 넣어주셔야 합니다.
                // 예시:
                // appState.goHome()
                // 또는
                // appState.currentRoot = .home
            }
        }
    }
    
    // 미션 타입별 뷰 분기 처리
    @ViewBuilder
    private func missionContent(
        type: String,
        id: Int,
        label: String
    ) -> some View {
        switch type {
        case "계산", "MATH":
            MathMissionView(alarmId: id, alarmLabel: label)
        case "운동", "WALK", "거리미션":
            DistanceMissionView(alarmId: id, alarmLabel: label)
        case "OX", "OX_QUIZ":
            OXMissionView(alarmId: id, alarmLabel: label)
        case "받아쓰기", "DICTATION":
            TypingMissionView(alarmId: id, alarmLabel: label)
        default:
            defaultAlarmView
        }
    }
    
    // MARK: - 기본 알람 화면 (미션 없을 때, 혹은 에러 시)
    
    private var defaultAlarmView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "alarm.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color.primary)
                .scaleEffect(animateIcon ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: animateIcon
                )
                .onAppear {
                    animateIcon = true
                }
            
            VStack(spacing: 16) {
                Text(alarmManager.triggeredAlarmLabel)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
                Text("일어나세요!")
                    .font(.body)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            Button(action: {
                alarmManager.stopAlarmSound()
            }) {
                Text("밀어서 중단")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color(hex: "F55641"))
                    .cornerRadius(30)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    AlarmPlayingOverlay()
}

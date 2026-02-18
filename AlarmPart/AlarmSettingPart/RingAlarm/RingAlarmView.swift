//
//  AlarmPlayingOverlay.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/15/26.
//

import SwiftUI
import AlarmKit
import Combine

struct AlarmPlayingOverlay: View {
    @StateObject private var alarmManager = AlarmKitManager.shared
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // ✅ 배경: 시스템 배경색 사용 (라이트: 흰색, 다크: 검은색)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // 미션 타입에 따라 실제 미션 뷰 연결
            if let missionType = alarmManager.triggeredMissionType, missionType != "NONE" {
                // alarmId가 있어야 API 호출 가능. 없으면(로컬/에러) 기본 화면.
                if let alarmId = alarmManager.triggeredAlarmId {
                    missionContent(type: missionType, id: alarmId, label: alarmManager.triggeredAlarmLabel)
                } else {
                    // ID가 없으면 그냥 기본 끄기 화면 보여주거나, 임시 ID로 진행
                    defaultAlarmView
                }
            } else {
                defaultAlarmView // 기본 알람 해제 화면
            }
        }
        .zIndex(9999)
    }
    
    // ✅ [수정] 미션 타입별 뷰 분기 처리 (SolvingMissionView 삭제 후 직접 연결)
    @ViewBuilder
    private func missionContent(type: String, id: Int, label: String) -> some View {
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
                // ✅ 배경이 흰색일 수 있으므로 primary(자동) 색상 사용
                .foregroundStyle(Color.primary)
                .scaleEffect(animateIcon ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateIcon)
                .onAppear { animateIcon = true }
            
            VStack(spacing: 16) {
                Text(alarmManager.triggeredAlarmLabel)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary) // ✅ 다크모드 대응
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

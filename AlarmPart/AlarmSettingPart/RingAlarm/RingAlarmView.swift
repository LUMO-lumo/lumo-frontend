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
            // ✅ [수정] 배경: 미션별 고정 색상 제거 -> 시스템 배경색 사용
            // 라이트모드: 흰색, 다크모드: 검은색
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // 미션 타입에 따라 다른 화면 보여주기
            if let missionType = alarmManager.triggeredMissionType, missionType != "NONE" {
                // ✅ [수정] 실제 미션 수행 로직을 담은 뷰 호출
                SolvingMissionView(missionType: missionType)
            } else {
                defaultAlarmView // 기본 알람 해제 화면
            }
        }
        .zIndex(999)
    }
    
    // MARK: - 기본 알람 화면
    private var defaultAlarmView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "alarm.fill")
                .font(.system(size: 100))
                // ✅ [수정] 배경이 흰색일 수 있으므로 primary(자동) 색상 사용
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
                    .foregroundStyle(.gray)
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

// MARK: - [핵심] 실제 문제를 풀게 하는 뷰
struct SolvingMissionView: View {
    let missionType: String
    @StateObject private var alarmManager = AlarmKitManager.shared
    
    // 수학 문제용 상태
    @State private var num1: Int = Int.random(in: 10...99)
    @State private var num2: Int = Int.random(in: 10...99)
    @State private var userAnswer: String = ""
    @State private var isWrong: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("\(missionType) 미션")
                .font(.headline)
                .foregroundStyle(Color.secondary) // ✅ 다크모드 대응
            
            // 미션 타입별 분기
            if missionType == "계산" || missionType == "수학문제" {
                MathProblemView
            } else {
                // 실제 앱에서는 여기서 각 미션 뷰(Distance, OX 등)가 RingAlarmView에서 분기처리되어 호출됨.
                // 이 뷰는 예비용(Fallback) 뷰입니다.
                GenericMissionView
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    // 수학 문제 UI (예비용)
    var MathProblemView: some View {
        VStack(spacing: 40) {
            Text("다음 문제를 풀어주세요")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary) // ✅ 다크모드 대응
            
            Text("\(num1) + \(num2) = ?")
                .font(.system(size: 60, weight: .heavy))
                .foregroundStyle(Color.primary) // ✅ 다크모드 대응
            
            TextField("정답 입력", text: $userAnswer)
                .keyboardType(.numberPad)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground)) // ✅ 배경색 변경
                .cornerRadius(15)
                .frame(width: 200)
            
            if isWrong {
                Text("틀렸습니다! 다시 시도하세요.")
                    .foregroundStyle(.red)
                    .fontWeight(.bold)
            }
            
            Button(action: checkAnswer) {
                Text("정답 확인")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(30)
            }
        }
    }
    
    // 그 외 미션 UI (예비용)
    var GenericMissionView: some View {
        VStack(spacing: 30) {
            Image(systemName: missionIcon(for: missionType))
                .font(.system(size: 80))
                .foregroundStyle(Color.primary)
                .padding()
                .background(Circle().fill(Color.gray.opacity(0.2)))
            
            Text("\(missionType) 미션을 완료해야\n알람이 꺼집니다.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)
            
            Button(action: {
                alarmManager.stopAlarmSound()
            }) {
                Text("미션 완료 (임시)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(30)
            }
        }
    }
    
    private func checkAnswer() {
        if let answer = Int(userAnswer), answer == (num1 + num2) {
            alarmManager.stopAlarmSound()
        } else {
            isWrong = true
            userAnswer = ""
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    private func missionIcon(for type: String) -> String {
        switch type {
        case "계산": return "x.squareroot"
        case "OX": return "checkmark.circle"
        case "받아쓰기": return "pencil.line"
        case "운동": return "figure.walk"
        default: return "alarm"
        }
    }
}

#Preview {
    AlarmPlayingOverlay()
}

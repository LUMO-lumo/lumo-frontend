//
//  AlarmChange.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 1/27/26.
//

import SwiftUI
import Foundation
import UserNotifications // [수정] AlarmKit 미인식 오류 해결을 위해 표준 프레임워크 사용

struct AlarmChange: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    
    // UI 상태 관리 변수
    @State private var alarmTitle: String = ""
    @State private var selectedMission: String = "수학문제"
    @State private var selectedDays: Set<Int> = [] // 0:월 ~ 6:일
    @State private var selectedTime: Date = Date()
    @State private var isSoundOn: Bool = false
    
    // 디자인 리소스 (아이콘 및 텍스트)
    let missions = [
        ("수학문제", "plus.forwardslash.minus"),
        ("OX 퀴즈", "checkmark.circle"),
        ("따라쓰기", "pencil"),
        ("거리미션", "figure.walk")
    ]
    
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 상단 네비게이션 바
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("알람 수정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 2. 알람 이름 입력 (핑크 배경)
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .trailing) {
                            TextField("알람 이름을 입력해주세요", text: $alarmTitle)
                                .padding()
                                .background(Color(hex: "FDF0EF")) // 디자인 시안의 연한 핑크
                                .cornerRadius(10)
                                .foregroundColor(.black)
                            Image(systemName: "pencil")
                                .foregroundColor(.gray)
                                .padding(.trailing, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 3. 미션 선택 (그리드 아이콘)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("미션 선택")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        HStack(spacing: 15) {
                            ForEach(missions, id: \.0) { mission in
                                MissionButton(
                                    title: mission.0,
                                    iconName: mission.1,
                                    isSelected: selectedMission == mission.0
                                ) { selectedMission = mission.0 }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 4. 요일 선택 (원형 버튼)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("요일 선택")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        HStack(spacing: 0) {
                            ForEach(0..<7) { index in
                                DayButton(
                                    text: days[index],
                                    isSelected: selectedDays.contains(index)
                                ) {
                                    if selectedDays.contains(index) {
                                        selectedDays.remove(index)
                                    } else {
                                        selectedDays.insert(index)
                                    }
                                }
                                if index != 6 { Spacer() }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 5. 시간 설정 (Wheel DatePicker + Pink Background)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("시간 설정")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        ZStack {
                            // 시간 선택기 배경
                            Color(hex: "FDF0EF").opacity(0.5)
                                .cornerRadius(20)
                            
                            // [수정] 표준 Wheel Picker 스타일
                            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(height: 200)
                                // WheelPicker의 기본 배경이 투명하게 보일 수 있도록 조정
                                .background(Color.clear)
                        }
                        .frame(height: 200)
                        .padding(.horizontal, 20)
                    }
                    
                    // 6. 하단 옵션 (레이블, 사운드)
                    VStack(spacing: 0) {
                        HStack {
                            Text("레이블")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                            Spacer()
                            Text("1교시 있는 날")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 15)
                        Divider()
                        HStack {
                            Text("사운드")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                            Spacer()
                            HStack(spacing: 5) {
                                Text("안 함")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 15)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 80)
                }
                .padding(.top, 20)
            }
            
            // 7. 설정하기 버튼
            Button(action: {
                scheduleAlarm()
                dismiss()
            }) {
                Text("설정하기")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "FF8C68")) // 코랄색
                    .cornerRadius(15)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .background(Color.white)
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    // MARK: - Alarm Logic (UserNotifications)
    
    // 알림 권한 요청
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
    }
    
    // 알람 스케줄링 (표준 API 사용)
    private func scheduleAlarm() {
        let content = UNMutableNotificationContent()
        content.title = alarmTitle.isEmpty ? "알람" : alarmTitle
        content.body = "\(selectedMission) 미션을 수행할 시간입니다!"
        content.sound = .default
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return }
        
        // 반복 요일이 없는 경우 (1회성)
        if selectedDays.isEmpty {
            var triggerDate = DateComponents()
            triggerDate.hour = hour
            triggerDate.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("알람 등록 실패: \(error)")
                } else {
                    print("1회성 알람 등록 성공: \(hour):\(minute)")
                }
            }
        } else {
            // 요일별 반복 알람 등록
            // selectedDays: 0(월) ~ 6(일) -> API에 맞게 변환 필요할 수 있음 (UserNotifications는 1=일, 2=월... 7=토)
            // 여기서는 단순화를 위해 개별 등록 로직 예시
            for dayIndex in selectedDays {
                var triggerDate = DateComponents()
                triggerDate.hour = hour
                triggerDate.minute = minute
                // 주의: Calendar.Component.weekday는 1(일요일) ~ 7(토요일)
                // 현재 UI의 days 배열: ["월", "화", "수", "목", "금", "토", "일"] -> 인덱스 0~6
                // 매핑: 0(월)->2, 1(화)->3, ... 5(토)->7, 6(일)->1
                let weekday: Int
                switch dayIndex {
                case 6: weekday = 1 // 일요일
                default: weekday = dayIndex + 2 // 월~토
                }
                triggerDate.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
                let request = UNNotificationRequest(identifier: "\(UUID().uuidString)_\(dayIndex)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
            print("반복 알람 등록 완료")
        }
    }
}

// MARK: - Helper Views

struct MissionButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "FF8C68").opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? Color(hex: "FF8C68") : .gray)
                }
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .black : .gray)
            }
        }
    }
}

struct DayButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color(hex: "D8CFC4") : Color(hex: "F5F5F5"))
                .clipShape(Circle())
        }
    }
}

// [수정] 중복 선언 오류 해결을 위해 extension 제거
// 프로젝트 내 다른 파일(AlarmMenuView 등)에 이미 정의되어 있습니다.

#Preview {
    AlarmChange()
}

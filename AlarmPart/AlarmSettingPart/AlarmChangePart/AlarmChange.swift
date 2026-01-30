//
//  AlarmChange.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 1/27/26.
//

import SwiftUI
import Foundation
import UserNotifications //권한 설정하는 방법
import Combine


// MARK: - ViewModel
class AlarmChangeViewModel: ObservableObject {
    // UI 상태 프로퍼티
    @Published var alarmTitle: String = ""
    @Published var selectedMission: String = "수학문제"
    @Published var selectedDays: Set<Int> = [] // 0:월 ~ 6:일 (View 기준)
    @Published var selectedTime: Date = Date()
    @Published var isSoundOn: Bool = false
    
    // 기존 데이터를 가져오는 역활
    init(alarm: Alarm? = nil) {
        if let alarm = alarm {
            print("[Debug] 알람 데이터 수신 성공: \(alarm.label), 시간: \(alarm.timeString)")
            
            self.alarmTitle = alarm.label
            self.selectedTime = alarm.time
            self.isSoundOn = alarm.isEnabled
        
            self.selectedDays = Set(alarm.repeatDays.map { ($0 + 6) % 7 })
            
            // [미션 매핑 로직]
            switch alarm.missionType {
            case "계산": self.selectedMission = "수학문제"
            case "받아쓰기": self.selectedMission = "따라쓰기"
            case "운동": self.selectedMission = "거리미션"
            case "OX": self.selectedMission = "OX 퀴즈"
            default: self.selectedMission = "수학문제"
            }
        } else {
            print("[Debug] 알람 데이터가 전달되지 않았습니다 (nil).")
        }
    }
    
    // 비즈니스 로직: 권한 요청
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
    }
    
    // 비즈니스 로직: 알람 스케줄링
    func scheduleAlarm() {
        let content = UNMutableNotificationContent()
        content.title = alarmTitle.isEmpty ? "알람" : alarmTitle
        content.body = "\(selectedMission) 미션을 수행할 시간입니다!"
        content.sound = .default
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return }
        
        // 1회성 알람
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
            // 반복 알람 (요일별 등록)
            for dayIndex in selectedDays {
                var triggerDate = DateComponents()
                triggerDate.hour = hour
                triggerDate.minute = minute
                
                // 요일 매핑: 0(월)->2 ... 6(일)->1
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

// MARK: - View
struct AlarmChange: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AlarmChangeViewModel
    init(alarm: Alarm? = nil) {
        // _viewModel은 @StateObject의 내부 저장소에 접근하는 방식입니다.
        _viewModel = StateObject(wrappedValue: AlarmChangeViewModel(alarm: alarm))
    }
    
    // 디자인 리소스
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
                    
                    // 2. 알람 이름 입력
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .trailing) {
                            TextField("알람 이름을 입력해주세요", text: $viewModel.alarmTitle)
                                .padding()
                                .background(Color(hex: "F2F4F7"))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                            Image(systemName: "pencil")
                                .foregroundColor(.gray)
                                .padding(.trailing, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 3. 미션 선택
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
                                    isSelected: viewModel.selectedMission == mission.0
                                ) {
                                    viewModel.selectedMission = mission.0
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 4. 요일 선택
                    VStack(alignment: .leading, spacing: 15) {
                        Text("요일 선택")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        HStack(spacing: 0) {
                            ForEach(0..<7) { index in
                                DayButton(
                                    text: days[index],
                                    isSelected: viewModel.selectedDays.contains(index)
                                ) {
                                    if viewModel.selectedDays.contains(index) {
                                        viewModel.selectedDays.remove(index)
                                    } else {
                                        viewModel.selectedDays.insert(index)
                                    }
                                }
                                if index != 6 { Spacer() }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 5. 시간 설정
                    VStack(alignment: .leading, spacing: 10) {
                        Text("시간 설정")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        ZStack {
                            Color(.white)
                                .cornerRadius(20)
                            
                            DatePicker("", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(height: 200)
                                .background(Color.clear)
                        }
                        .frame(height: 200)
                        .padding(.horizontal, 20)
                    }
                    
                    // 6. 하단 옵션
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
                    
                    // 7. 설정하기 버튼
                    Button(action: {
                        viewModel.scheduleAlarm()
                        dismiss()
                    }) {
                        Text("설정하기")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "F55641"))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
               
                .padding(.bottom, 40)
                
            }
        }
        .navigationBarHidden(true)
        .background(Color.white)
        .onAppear {
            viewModel.requestNotificationPermission()
        }
    }
}

// MARK: - 버튼 기능

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
                    //이후 이미지 추가할 예정
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
                .background(isSelected ? Color(hex: "F55641") : Color(hex: "F2F4F7"))
                .clipShape(Circle())
        }
    }
}

#Preview {
    AlarmChange(alarm: Alarm.dummyData[0])
}

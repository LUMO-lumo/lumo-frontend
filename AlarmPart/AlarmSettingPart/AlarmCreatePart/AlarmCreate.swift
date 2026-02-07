//
//  AlarmCreating.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 1/27/26.
//

import Moya
import Combine
import SwiftUI
import Foundation
import UserNotifications
import AlarmKit

// MARK: - ViewModel for Creation
class AlarmCreateViewModel: ObservableObject {
    // UI 상태 프로퍼티 (초기값은 비어있거나 기본값)
    @Published var alarmTitle: String = ""
    @Published var selectedMission: String = "수학문제"
    @Published var selectedDays: Set<Int> = [] // 0:월 ~ 6:일 (View 기준)
    @Published var selectedTime: Date = Date()
    @Published var isSoundOn: Bool = true // 생성 시 기본은 켜짐
    @Published var alarmSound: String = "기본음"
    
    // 알람 생성 로직
    func createNewAlarm() -> Alarm {
        // 1. 요일 매핑 (View: 0~6 -> Model: 0~6 / 일~토 기준에 맞춰 변환)
        let mappedDays = selectedDays.map { ($0 + 1) % 7 }.sorted()

        let mType: String
        switch selectedMission {
        case "수학문제": mType = "계산"
        case "따라쓰기": mType = "받아쓰기"
        case "거리미션": mType = "운동"
        case "OX 퀴즈": mType = "OX"
        default: mType = "계산"
        }
        
        // 2. 새 알람 객체 생성
        return Alarm(
            time: selectedTime,
            label: alarmTitle.isEmpty ? "새 알람" : alarmTitle,
            isEnabled: isSoundOn,
            repeatDays: mappedDays,
            missionTitle: selectedMission,
            missionType: mType
        )
    }
    
    // [Server] 알람 생성 API 호출 (Placeholder)
    func requestCreateAlarm(completion: @escaping (Bool) -> Void) {
        let newAlarm = createNewAlarm()
        print("====== [알람 생성 요청] ======")
        print("라벨: \(newAlarm.label)")
        print("시간: \(newAlarm.timeString)")
        print("미션: \(newAlarm.missionType)")
        print("사운드: \(alarmSound)")
        print("==========================")
        
        // TODO: Moya Provider를 사용하여 'createAlarm' API 호출
        // provider.request(.createAlarm(data: newAlarm)) { ... }
        
        // 현재는 성공했다고 가정
        completion(true)
    }
    
    // 로컬 알림 스케줄링
    func scheduleLocalNotification() {
        // 위젯에서 알람이 울리게 하는 방법
        let content = UNMutableNotificationContent()
        content.title = alarmTitle.isEmpty ? "알람" : alarmTitle
        content.body = "\(selectedMission) 미션을 수행할 시간입니다!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(alarmSound).m4a")) // 실제 사운드 파일명 매칭 필요
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return }
        
        if selectedDays.isEmpty {
            var triggerDate = DateComponents()
            triggerDate.hour = hour
            triggerDate.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            for dayIndex in selectedDays {
                var triggerDate = DateComponents()
                triggerDate.hour = hour
                triggerDate.minute = minute
                
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
        }
    }
}

// MARK: - View
struct AlarmCreate: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AlarmCreateViewModel()
    
    // 생성 완료 후 상위 뷰에 알리기 위한 클로저
    var onCreate: ((Alarm) -> Void)?
    
    // 디자인 리소스
    let missions = [
        ("수학문제", "MathMission"),
        ("OX 퀴즈", "OXMission"),
        ("따라쓰기", "WriteMission"),
        ("거리미션", "DestMission")
    ]
    
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 상단 네비게이션 바
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.gray)
                }
                Spacer()
                Text("알람 생성")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .foregroundStyle(.clear)
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
                                .foregroundStyle(.black)
                            Image(systemName: "pencil")
                                .foregroundStyle(.gray)
                                .padding(.trailing, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 3. 미션 선택
                    VStack(alignment: .leading, spacing: 15) {
                        Text("미션 선택")
                            .font(.system(size: 14))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                        HStack(spacing: 15) {
                            ForEach(missions, id: \.0) { mission in
                                CreateMissionButton(
                                    title: mission.0,
                                    imageName: mission.1,
                                    isSelected: viewModel.selectedMission == mission.0
                                ) {
                                    viewModel.selectedMission = mission.0
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 4. 요일 선택
                    VStack(alignment: .leading, spacing: 15) {
                        Text("요일 선택")
                            .font(.system(size: 14))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                        HStack(spacing: 0) {
                            ForEach(0..<7) { index in
                                CreateDayButton(
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
                            .foregroundStyle(.black)
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
                                .foregroundStyle(.black)
                            Spacer()
                            Text("1교시 있는 날") // 예시 텍스트
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 15)
                        Divider()
                        
                        // [수정] 사운드 설정 버튼 (NavigationLink 적용)
                        NavigationLink(destination: SoundSettingView(alarmSound: $viewModel.alarmSound)) {
                            HStack {
                                Text("사운드")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.black)
                                Spacer()
                                HStack(spacing: 5) {
                                    // 현재 선택된 알람 사운드 표시
                                    Text(viewModel.alarmSound)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(.vertical, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 7. 생성하기 버튼
                    Button(action: {
                        viewModel.scheduleLocalNotification()
                        viewModel.requestCreateAlarm { success in
                            if success {
                                let newAlarm = viewModel.createNewAlarm()
                                onCreate?(newAlarm)
                                dismiss()
                            }
                        }
                    }) {
                        Text("생성하기")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "F55641"))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .background(Color.white)
    }
}

// MARK: - Private Components

private struct CreateMissionButton: View {
    let title: String
    let imageName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "FF8C68").opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .opacity(isSelected ? 1.0 : 0.4)
                }
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .black : .gray)
            }
        }
    }
}

private struct CreateDayButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .gray)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color(hex: "F55641") : Color(hex: "F2F4F7"))
                .clipShape(Circle())
        }
    }
}

#Preview {
    AlarmCreate()
}

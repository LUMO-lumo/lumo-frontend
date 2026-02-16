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

// MARK: - ViewModel
class AlarmCreateViewModel: ObservableObject {
    @Published var alarmTitle: String = ""
    @Published var selectedMission: String = "수학문제"
    @Published var selectedDays: Set<Int> = []
    @Published var selectedTime: Date = Date()
    @Published var isSoundOn: Bool = true
    @Published var alarmSound: String = "기본음"
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func createNewAlarm() -> Alarm {
        let mappedDays = selectedDays.map { ($0 + 1) % 7 }.sorted()
        let mType: String
        switch selectedMission {
        case "수학문제": mType = "계산"
        case "따라쓰기": mType = "받아쓰기"
        case "거리미션": mType = "운동"
        case "OX 퀴즈": mType = "OX"
        default: mType = "계산"
        }
        
        // 앱 내에서는 '한국어' 사운드 이름을 사용
        return Alarm(
            time: selectedTime,
            label: alarmTitle.isEmpty ? "새 알람" : alarmTitle,
            isEnabled: isSoundOn,
            repeatDays: mappedDays,
            missionTitle: selectedMission,
            missionType: mType,
            soundName: alarmSound
        )
    }
    
    // ✅ [수정] 전송될 JSON을 콘솔에 상세히 출력하는 디버깅 로직 추가
    func requestCreateAlarm(completion: @escaping (Alarm?) -> Void) {
        let newAlarm = createNewAlarm()
        
        // AlarmDTO.swift의 toDictionary()를 사용하여 딕셔너리 생성
        let params = newAlarm.toDictionary()
        
        // 🔍 [Debug] 실제 서버로 날아가는 JSON 문자열 확인
        // 이 부분이 추가되었습니다: 딕셔너리를 JSON 문자열로 변환하여 출력
        if let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("\n==================================================")
            print("🚀 [Debug] 서버로 전송할 JSON Body (Raw String):")
            print(jsonString)
            print("==================================================\n")
        } else {
            print("⚠️ [Debug] JSON 변환 실패: params 딕셔너리를 확인하세요.")
            print(params)
        }
        
        // 요청 전송
        AlarmService.shared.createAlarm(params: params) { result in
            switch result {
            case .success(let dto):
                print("✅ 알람 생성 성공: ID \(dto.alarmId)")
                let createdAlarm = Alarm(from: dto)
                completion(createdAlarm)
            case .failure(let error):
                print("❌ 알람 생성 실패: \(error.localizedDescription)")
                // 에러 발생 시 더 자세한 정보가 있다면 출력 (MainAPIClient에서 이미 출력 중)
                completion(nil)
            }
        }
    }
}

// MARK: - View
struct AlarmCreate: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AlarmCreateViewModel()
    
    var onCreate: ((Alarm) -> Void)?
    
    let missions = [("수학문제", "MathMission"), ("OX 퀴즈", "OXMission"), ("따라쓰기", "WriteMission"), ("거리미션", "DestMission")]
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.gray)
                }
                Spacer()
                Text("알람 생성")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color(uiColor: .systemBackground))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .trailing) {
                            TextField("알람 이름을 입력해주세요", text: $viewModel.alarmTitle)
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(10)
                                .foregroundStyle(Color.primary)
                            Image(systemName: "pencil").foregroundStyle(.gray).padding(.trailing, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("미션 선택").font(.system(size: 14)).foregroundStyle(Color.primary).padding(.horizontal, 20)
                        HStack(spacing: 15) {
                            ForEach(missions, id: \.0) { mission in
                                CreateMissionButton(title: mission.0, imageName: mission.1, isSelected: viewModel.selectedMission == mission.0) {
                                    viewModel.selectedMission = mission.0
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("요일 선택").font(.system(size: 14)).foregroundStyle(Color.primary).padding(.horizontal, 20)
                        HStack(spacing: 0) {
                            ForEach(0..<7) { index in
                                CreateDayButton(text: days[index], isSelected: viewModel.selectedDays.contains(index)) {
                                    if viewModel.selectedDays.contains(index) { viewModel.selectedDays.remove(index) }
                                    else { viewModel.selectedDays.insert(index) }
                                }
                                if index != 6 { Spacer() }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("시간 설정").font(.system(size: 14)).foregroundStyle(Color.primary).padding(.horizontal, 20)
                        ZStack {
                            Color(uiColor: .secondarySystemBackground).cornerRadius(20)
                            DatePicker("", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel).labelsHidden().frame(height: 200).background(Color.clear)
                        }
                        .frame(height: 200).padding(.horizontal, 20)
                    }
                    
                    VStack(spacing: 0) {
                        HStack {
                            Text("레이블").font(.system(size: 14)).foregroundStyle(Color.primary)
                            Spacer()
                            Text("1교시 있는 날").font(.system(size: 14)).foregroundStyle(.gray)
                        }
                        .padding(.vertical, 15)
                        Divider()
                        
                        NavigationLink(destination: SoundSettingView(alarmSound: $viewModel.alarmSound)) {
                            HStack {
                                Text("사운드").font(.system(size: 14)).foregroundStyle(Color.primary)
                                Spacer()
                                HStack(spacing: 5) {
                                    Text(viewModel.alarmSound).font(.system(size: 14)).foregroundStyle(.gray)
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(.gray)
                                }
                            }
                            .padding(.vertical, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        // 서버 통신 시도
                        viewModel.requestCreateAlarm { createdAlarm in
                            if let alarm = createdAlarm {
                                onCreate?(alarm)
                                dismiss()
                            } else {
                                print("서버 생성 실패로 인해 로컬 알람을 생성하지 않습니다.")
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
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            viewModel.requestNotificationPermission()
        }
    }
}

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
                    Image(imageName).resizable().scaledToFit().frame(width: 30, height: 30).opacity(isSelected ? 1.0 : 0.4)
                }
                Text(title).font(.system(size: 12)).foregroundStyle(isSelected ? Color.primary : Color.gray)
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
                .background(isSelected ? Color(hex: "F55641") : Color(uiColor: .secondarySystemBackground))
                .clipShape(Circle())
        }
    }
}

#Preview {
    AlarmCreate()
}

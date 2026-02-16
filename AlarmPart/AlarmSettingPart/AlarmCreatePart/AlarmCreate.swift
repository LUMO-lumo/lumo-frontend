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
    
    // [연동] 사운드 저장 변수
    @Published var alarmSound: String = "기본음"
    
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
        
        // [추가됨] soundName 저장
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
    
    // [수정됨] 실제 서버 API 호출 및 DTO 연결
    func requestCreateAlarm(completion: @escaping (Bool) -> Void) {
        // 1. 로컬 알람 객체 생성
        let newAlarm = createNewAlarm()
        
        // 2. 서버 요청용 파라미터 변환 (AlarmModel의 extension 활용 - DTO 변환)
        let params = newAlarm.toDictionary()
        
        print("[Debug] 알람 생성 요청: \(params)")
        
        // 3. 서비스 호출 (서버 통신)
        AlarmService.shared.createAlarm(params: params) { result in
            switch result {
            case .success(let dto):
                print("알람 생성 성공: ID \(dto.alarmId)")
                // 성공 시 true 반환
                completion(true)
            case .failure(let error):
                print("알람 생성 실패: \(error.localizedDescription)")
                // 실패 시 false 반환 (필요 시 에러 처리 로직 추가 가능)
                completion(false)
            }
        }
    }
    
    func scheduleLocalNotification() {}
}

// MARK: - View
struct AlarmCreate: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AlarmCreateViewModel()
    
    var onCreate: ((Alarm) -> Void)?
    
    let missions = [
        ("수학문제", "MathMission"),
        ("OX 퀴즈", "OXMission"),
        ("따라쓰기", "WriteMission"),
        ("거리미션", "DestMission")
    ]
    
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
                    .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .foregroundStyle(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color(uiColor: .systemBackground)) // ✅ 다크모드 대응
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .trailing) {
                            TextField("알람 이름을 입력해주세요", text: $viewModel.alarmTitle)
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground)) // ✅ 다크모드 대응
                                .cornerRadius(10)
                                .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                            Image(systemName: "pencil")
                                .foregroundStyle(.gray)
                                .padding(.trailing, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("미션 선택")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.primary) // ✅ 다크모드 대응
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
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("요일 선택")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.primary) // ✅ 다크모드 대응
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
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("시간 설정")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                            .padding(.horizontal, 20)
                        
                        ZStack {
                            Color(uiColor: .secondarySystemGroupedBackground) // ✅ 다크모드 대응
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
                    
                    VStack(spacing: 0) {
                        HStack {
                            Text("레이블")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                            Spacer()
                            Text("1교시 있는 날")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 15)
                        Divider()
                        
                        // [연결] SoundSettingView로 이동 (Binding 전달)
                        NavigationLink(destination: SoundSettingView(alarmSound: $viewModel.alarmSound)) {
                            HStack {
                                Text("사운드")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                                Spacer()
                                HStack(spacing: 5) {
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
                    
                    Button(action: {
                        let newAlarm = viewModel.createNewAlarm()
                        
                        // ✅ [수정] 중복 호출 제거
                        // 여기서 AlarmKitManager를 직접 호출하지 않습니다.
                        // viewModel.requestCreateAlarm 완료 후 onCreate 클로저를 통해
                        // AlarmMenuView -> AlarmViewModel.addAlarm 내에서 한 번만 등록하도록 합니다.
                        
                        viewModel.requestCreateAlarm { success in
                            if success {
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
        .background(Color(uiColor: .systemBackground)) // ✅ 다크모드 대응
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
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .opacity(isSelected ? 1.0 : 0.4)
                }
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color.primary : .gray) // ✅ 다크모드 대응
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
                // ✅ 다크모드 대응
                .background(isSelected ? Color(hex: "F55641") : Color(uiColor: .secondarySystemBackground))
                .clipShape(Circle())
        }
    }
}

#Preview {
    AlarmCreate()
}

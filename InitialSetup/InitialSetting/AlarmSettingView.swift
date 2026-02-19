//
//  OnboardingAlarmSetupView.swift
//  Lumo
//
//  Created by User on 2/19/26.
//

import SwiftUI
import Combine

// MARK: - 뷰모델
class OnboardingAlarmViewModel: ObservableObject {
    @Published var alarmTitle: String = ""
    @Published var selectedMission: String = "수학문제"
    @Published var selectedDays: Set<Int> = []
    @Published var selectedTime: Date = Date()
    @Published var isSoundOn: Bool = true
    @Published var alarmSound: String = "기본음"
}

// MARK: - 뷰
struct OnboardingAlarmSetupView: View {
    @Binding var currentPage: Int
    @StateObject private var viewModel = OnboardingAlarmViewModel()
    
    // 네비게이션 대신 ZStack 오버레이 제어용 변수
    @State private var showSoundSettings: Bool = false
    
    let missions = [
        ("수학문제", "MathMission"),
        ("OX 퀴즈", "OXMission"),
        ("따라쓰기", "WriteMission"),
        ("거리미션", "DestMission")
    ]
    
    let days = ["월", "화", "수", "목", "금", "토", "일"]
    
    var body: some View {
        ZStack {
            // 메인 컨텐츠
            VStack(spacing: 0) {
                // 상단 헤더
                HStack {
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
                        
                        // 1. 알람 이름 입력
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack(alignment: .trailing) {
                                TextField("알람 이름을 입력해주세요", text: $viewModel.alarmTitle)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(10)
                                    .foregroundStyle(Color.primary)
                                Image(systemName: "pencil")
                                    .foregroundStyle(.gray)
                                    .padding(.trailing, 15)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 2. 미션 선택
                        VStack(alignment: .leading, spacing: 15) {
                            Text("미션 선택")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 20)
                            HStack(spacing: 15) {
                                ForEach(missions, id: \.0) { mission in
                                    OnboardingMissionButton(
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
                        
                        // 3. 요일 선택
                        VStack(alignment: .leading, spacing: 15) {
                            Text("요일 선택")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 20)
                            HStack(spacing: 0) {
                                ForEach(0..<7) { index in
                                    OnboardingDayButton(
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
                        
                        // 4. 시간 설정
                        VStack(alignment: .leading, spacing: 10) {
                            Text("시간 설정")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 20)
                            
                            ZStack {
                                Color(uiColor: .secondarySystemGroupedBackground)
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
                        
                        // 5. 추가 옵션 (사운드 설정으로 이동)
                        VStack(spacing: 0) {
                            HStack {
                                Text("레이블")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text("1교시 있는 날")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)
                            }
                            .padding(.vertical, 15)
                            Divider()
                            
                            // 버튼으로 화면 전환 (NavigationLink 아님)
                            Button(action: {
                                // 키보드 내리기
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                withAnimation {
                                    showSoundSettings = true
                                }
                            }) {
                                HStack {
                                    Text("사운드")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.primary)
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
                        
                        // 하단 패딩 확보
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(Color(uiColor: .systemBackground))
            
            // [사운드 설정 오버레이]
            if showSoundSettings {
                OnboardingSoundSetupView(
                    alarmSound: $viewModel.alarmSound,
                    isPresented: $showSoundSettings
                )
                .background(Color(uiColor: .systemBackground))
                .transition(.move(edge: .trailing)) // 오른쪽에서 슬라이드 애니메이션
                .zIndex(1) // 최상단에 표시
            }
        }
    }
}

// MARK: - 내부 컴포넌트
private struct OnboardingMissionButton: View {
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
                    if UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .opacity(isSelected ? 1.0 : 0.4)
                    } else {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(isSelected ? Color(hex: "F55641") : .gray)
                    }
                }
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color.primary : .gray)
            }
        }
    }
}

private struct OnboardingDayButton: View {
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
    OnboardingAlarmSetupView(currentPage: .constant(1))
}

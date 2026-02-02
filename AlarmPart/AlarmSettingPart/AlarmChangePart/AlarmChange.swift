//
//  AlarmChange.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 1/27/26.
//

import SwiftUI
import Foundation
import Combine
import AlarmKit
import Moya

// MARK: - View
struct AlarmChange: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AlarmChangeViewModel
    
    // 저장을 위한 클로저
    var onSave: ((Alarm) -> Void)?
    
    init(alarm: Alarm? = nil, onSave: ((Alarm) -> Void)? = nil) {
        // ViewModel 주입
        _viewModel = StateObject(wrappedValue: AlarmChangeViewModel(alarm: alarm))
        self.onSave = onSave
    }
    
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
                Text("알람 수정")
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
                    
                    // 2. 알람 이름 입력 (TextField)
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
                            // AlarmChangeModel의 정적 데이터 사용
                            ForEach(AlarmChangeModel.missions, id: \.0) { mission in
                                MissionButton(
                                    title: mission.title,
                                    imageName: mission.imageName,
                                    isSelected: viewModel.selectedMission == mission.title
                                ) {
                                    viewModel.selectedMission = mission.title
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
                            // AlarmChangeModel의 요일 데이터 사용
                            ForEach(0..<AlarmChangeModel.days.count, id: \.self) { index in
                                DayButton(
                                    text: AlarmChangeModel.days[index],
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
                            Text("1교시 있는 날")
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
                    
                    // 7. 설정하기 버튼
                    Button(action: {
                        viewModel.scheduleAlarm()
                        // 변경된 내용(타이틀 포함)을 부모 뷰로 전달
                        let updatedAlarm = viewModel.getUpdatedAlarm()
                        onSave?(updatedAlarm)
                        dismiss()
                    }) {
                        Text("설정하기")
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
        .onAppear {
            viewModel.requestNotificationPermission()
        }
    }
}

// MARK: - Subviews (Components)

struct MissionButton: View {
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

struct DayButton: View {
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
    AlarmChange(alarm: Alarm.dummyData[0])
}

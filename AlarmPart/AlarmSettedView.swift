//
//  AlarmSettingView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/13/26.
//

// 알람 설정한 거 보이는 상자 (개별 Row View)

import SwiftUI
import Foundation
import AlarmKit

struct AlarmSettedView: View {
    @Binding var alarm: Alarm
    var onDelete: () -> Void
    var onUpdate: ((Alarm) -> Void)?
    
    // ✅ [추가] 토글 전용 클로저
    var onToggle: ((Bool) -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    let deleteButtonWidth: CGFloat = 80
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        ZStack {
            // [배경 레이어] 삭제 버튼
            HStack {
                Spacer()
                Button(action: {
                    withAnimation { onDelete() }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F55641"))
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.trailing, 10)
                .opacity(offset < -40 ? 1 : 0)
            }
            
            // [상단 레이어] 카드 내용
            VStack(alignment: .leading, spacing: 12) {
                
                HStack(alignment: .center) {
                    Text(alarm.timeString)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                    
                    Spacer()
                    
                    Toggle("", isOn: $alarm.isEnabled)
                        .labelsHidden()
                        .tint(Color(hex: "F55641"))
                        .onChange(of: alarm.isEnabled) { oldValue, newValue in
                            // ✅ [수정] 전체 업데이트가 아닌 전용 토글 이벤트 호출
                            onToggle?(newValue)
                        }
                }
                
                TextField("알람 이름", text: $alarm.label)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .onSubmit {
                        firstupdateAlarmOnServer()
                    }
                
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Button(action: {
                            toggleDay(index)
                        }) {
                            ZStack {
                                Circle()
                                    // ✅ 다크모드 대응: 비활성화 시 시스템 그레이 사용
                                    .fill(alarm.repeatDays.contains(index) ? Color(hex: "F55641") : Color(uiColor: .systemGray5))
                                    .frame(width: 30, height: 30)
                                
                                Text(days[index])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(alarm.repeatDays.contains(index) ? .white : .gray)
                            }
                        }
                    }
                }
                
                HStack {
                    HStack(spacing: 6) {
                        Text(alarm.missionType)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(alarm.missionTitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.primary.opacity(0.8)) // ✅ 다크모드 대응
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    // ✅ 다크모드 대응: 배경 투명도 조절 혹은 시스템 컬러 사용
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    NavigationLink(destination: AlarmChange(alarm: alarm, onSave: { updatedAlarm in
                        self.alarm = updatedAlarm
                        firstupdateAlarmOnServer()
                    })) {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.gray)
                            .rotationEffect(.degrees(90))
                            .padding(4)
                    }
                }
            }
            .padding(20)
            // ✅ 다크모드 대응: 카드 배경색 (라이트: 연회색 / 다크: 짙은 회색)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            if value.translation.width < 0 {
                                self.offset = value.translation.width
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -60 {
                                self.offset = -deleteButtonWidth
                                self.isSwiped = true
                            } else {
                                self.offset = 0
                                self.isSwiped = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if isSwiped {
                    withAnimation {
                        self.offset = 0
                        self.isSwiped = false
                    }
                }
            }
        }
    }
    
    private func toggleDay(_ index: Int) {
        if let existingIndex = alarm.repeatDays.firstIndex(of: index) {
            alarm.repeatDays.remove(at: existingIndex)
        } else {
            alarm.repeatDays.append(index)
            alarm.repeatDays.sort()
        }
        firstupdateAlarmOnServer()
    }
    
    private func firstupdateAlarmOnServer() {
        onUpdate?(alarm)
    }
}

#Preview {
    AlarmSettedView(alarm: .constant(Alarm.dummyData[0]), onDelete: {})
}

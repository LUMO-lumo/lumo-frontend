//
//  AlarmSettingView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/13/26.
//

// 알람 설정한 거 보이는 상자 (개별 Row View)

import SwiftUI
import Foundation

struct AlarmSettedView: View {
    @Binding var alarm: Alarm
    // 삭제 이벤트를 부모 뷰로 전달하기 위한 클로저
    var onDelete: () -> Void
    //이후 서버하고 연결하는 기능으로 사용
    var onUpdate: ((Alarm) -> Void)?
    
    // 스와이프 상태 관리
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    let deleteButtonWidth: CGFloat = 80
    
    // 요일 표시를 위한 배열
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        onDelete()
                    }
                }) {
                    ZStack {
                        // 디자인에 맞는 붉은색 (F55641) 사용
                        Circle()
                            .fill(Color(hex: "F55641"))
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 10)
                .opacity(offset < -40 ? 1 : 0) // 스와이프 시 서서히 나타남
            }
            
            // [상단 레이어] 기존 알람 카드 내용
            VStack(alignment: .leading, spacing: 12) {
                
                // 1. 시간 및 토글 스위치
                HStack(alignment: .center) {
                    Text(alarm.timeString)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Toggle("", isOn: $alarm.isEnabled)
                        .labelsHidden()
                        .tint(Color(hex: "F55641"))
                        .onChange(of: alarm.isEnabled) { oldValue, newValue in
                            // 토글 상태 변경 시 서버 업데이트 로직 호출
                            updateAlarmOnServer()
                        }
                }
                
                // 2. 라벨 (아침 기상 등)
                Text(alarm.label)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                // 3. 요일 반복 버튼들
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Button(action: {
                            toggleDay(index)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(alarm.repeatDays.contains(index) ? Color(hex: "F55641") : Color(hex:"DDE1E8"))
                                    .frame(width: 30, height: 30)
                                
                                Text(days[index])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(alarm.repeatDays.contains(index) ? .white : .gray)
                            }
                        }
                    }
                }
                
                // 4. 미션 태그
                HStack {
                    HStack(spacing: 6) {
                        Text(alarm.missionType)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(alarm.missionTitle)
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // [수정 완료] 여기서 현재 알람 데이터(alarm)를 AlarmChange로 넘겨줍니다.
                    NavigationLink(destination: AlarmChange(alarm: alarm)) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(90))
                            .padding(4)
                    }
                }
            }
            .padding(20)
            .background(Color(hex: "F2F4F7")) // 기존 배경색 유지
            .cornerRadius(20)
            // 그림자 효과로 카드 느낌 주기
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .offset(x: offset)
            .gesture(
                // 수직 스크롤과 기능이 겹치는 문제가 생김
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onChanged { value in
                        // 왼쪽으로만 스와이프 허용
                        if value.translation.width < 0 {
                            self.offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            // -60 이상 당기면 버튼 보인 상태로 고정
                            if value.translation.width < -60 {
                                self.offset = -deleteButtonWidth
                                self.isSwiped = true
                            } else {
                                // 아니면 원위치
                                self.offset = 0
                                self.isSwiped = false
                            }
                        }
                    }
            )
            // 열린 상태에서 카드 터치 시 닫기
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
    
    // MARK: - Logic Helpers
    
    /// 요일 선택/해제 로직
    private func toggleDay(_ index: Int) {
        if let existingIndex = alarm.repeatDays.firstIndex(of: index) {
            alarm.repeatDays.remove(at: existingIndex)
        } else {
            alarm.repeatDays.append(index)
            alarm.repeatDays.sort()
        }
        updateAlarmOnServer()
    }

    private func updateAlarmOnServer() {
        print("====== [서버 통신] ======")
        print("알람 ID: \(alarm.id) 업데이트")
        print("변경된 반복 요일: \(alarm.repeatDays)")
        print("변경된 활성 상태: \(alarm.isEnabled)")
        print("DB에 저장 요청을 보냅니다...")
        print("========================")
        onUpdate?(alarm)
    }
}

#Preview {
    AlarmSettedView(alarm: .constant(Alarm.dummyData[0]), onDelete: {})
}

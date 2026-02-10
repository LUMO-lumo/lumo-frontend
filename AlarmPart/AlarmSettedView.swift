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
    // 삭제 이벤트를 부모 뷰로 전달하기 위한 클로저
    var onDelete: () -> Void
    // 데이터 변경 시(요일 등) 부모 뷰나 서버로 알리기 위한 클로저
    var onUpdate: ((Alarm) -> Void)?
    
    // 스와이프 상태 관리
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    let deleteButtonWidth: CGFloat = 80
    
    // 요일 표시를 위한 배열
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        ZStack {
            // [배경 레이어] 삭제 버튼 (오른쪽)
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
                            .foregroundStyle(.white)
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
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    Toggle("", isOn: $alarm.isEnabled)
                        .labelsHidden()
                        .tint(Color(hex: "F55641"))
                        // iOS 17 대응: 매개변수 2개(oldValue, newValue)를 받는 클로저 사용
                        .onChange(of: alarm.isEnabled) { oldValue, newValue in
                            // 토글 상태 변경 시 서버 업데이트 로직 호출
                            firstupdateAlarmOnServer()
                        }
                }
                
                // 2. 라벨 (아침 기상 등) - TextField로 변경됨
                TextField("알람 이름", text: $alarm.label)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .onSubmit {
                        // 엔터(완료)를 누르면 서버 동기화 함수 호출
                        firstupdateAlarmOnServer()
                    }
                
                // 3. 요일 반복 버튼들
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Button(action: {
                            toggleDay(index)
                        }) {
                            ZStack {
                                Circle()
                                    // 요청하신 색상(F55641) 적용
                                    .fill(alarm.repeatDays.contains(index) ? Color(hex: "F55641") : Color(hex:"DDE1E8"))
                                    .frame(width: 30, height: 30)
                                
                                Text(days[index])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(alarm.repeatDays.contains(index) ? .white : .gray)
                            }
                        }
                    }
                }
                
                // 4. 미션 태그 및 수정 페이지 이동
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
                            .foregroundStyle(.black.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // 수정 페이지(AlarmChange)로 이동할 때 onSave 연결
                    NavigationLink(destination: AlarmChange(alarm: alarm, onSave: { updatedAlarm in
                        // 1. 수정된 알람 데이터를 받아와서 현재 뷰의 데이터(Binding)를 업데이트
                        self.alarm = updatedAlarm
                        
                        // 2. 서버나 상위 뷰에도 변경 알림
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
            .background(Color(hex: "F2F4F7")) // 기존 배경색 유지
            .cornerRadius(20)
            // 그림자 효과로 카드 느낌 주기
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .offset(x: offset)
            // [수정된 제스처 로직]
            // minimumDistance: 20 -> 약간의 움직임은 무시하여 스크롤 뷰가 터치를 가져갈 기회를 줌
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        // 수직 움직임보다 수평 움직임이 클 때만 스와이프 동작 인식 (스크롤 방해 방지)
                        if abs(value.translation.width) > abs(value.translation.height) {
                            // 왼쪽으로만 스와이프 허용
                            if value.translation.width < 0 {
                                self.offset = value.translation.width
                            }
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
        // UI 업데이트 (Binding을 통해 즉시 반영)
        if let existingIndex = alarm.repeatDays.firstIndex(of: index) {
            alarm.repeatDays.remove(at: existingIndex)
        } else {
            alarm.repeatDays.append(index)
            alarm.repeatDays.sort() // 요일 순서대로 정렬
        }
        
        // 서버 동기화 호출
        firstupdateAlarmOnServer()
    }
    
    /// 서버(DB)에 변경 사항을 저장하는 함수
    private func firstupdateAlarmOnServer() {
        print("====== [데이터 업데이트] ======")
        print("알람 ID: \(alarm.id) 업데이트")
        print("제목: \(alarm.label)")
        print("시간: \(alarm.timeString)")
        print("반복 요일: \(alarm.repeatDays)")
        print("============================")
        
        // 상위 뷰로 이벤트 전달
        onUpdate?(alarm)
    }
}

#Preview {
    AlarmSettedView(alarm: .constant(Alarm.dummyData[0]), onDelete: {})
}

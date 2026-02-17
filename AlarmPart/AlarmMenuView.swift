//
//  AlarmView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

import SwiftUI
import Foundation
import Moya
import CombineMoya
import AlarmKit

struct AlarmMenuView: View {
    @StateObject private var viewModel = AlarmViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                
                VStack(alignment: .leading) {
                    Text("알람 목록")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.primary) // ✅ 다크모드 대응 (Black -> White)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // [수정 1] $viewModel.alarms 대신 viewModel.alarms 사용 (값으로 순회)
                            ForEach(viewModel.alarms) { alarm in
                                
                                // [수정 2] 안전한 커스텀 바인딩 생성
                                // 배열의 인덱스가 바뀌거나 삭제되어도 안전하게 ID로 찾아서 연결해줍니다.
                                let alarmBinding = Binding<Alarm>(
                                    get: {
                                        // 현재 배열에서 이 ID를 가진 최신 알람을 찾아서 반환
                                        // (만약 삭제되어서 없으면 현재 alarm 값을 그냥 반환해서 크래시 방지)
                                        guard let index = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) else {
                                            return alarm
                                        }
                                        return viewModel.alarms[index]
                                    },
                                    set: { newAlarm in
                                        // 수정된 내용을 배열에 반영
                                        if let index = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                            viewModel.alarms[index] = newAlarm
                                        }
                                    }
                                )
                                
                                AlarmSettedView(
                                    alarm: alarmBinding, // 위에서 만든 안전한 바인딩 전달
                                    onDelete: {
                                        withAnimation {
                                            viewModel.deleteAlarm(id: alarm.id)
                                        }
                                    },
                                    onUpdate: { updatedAlarm in
                                        viewModel.updateAlarm(updatedAlarm)
                                    },
                                    onToggle: { isOn in
                                        viewModel.toggleAlarmState(alarm: alarm, isOn: isOn)
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 150)
                    }
                }
                
                NavigationLink(destination: AlarmCreate(onCreate: { newAlarm in
                    withAnimation {
                        viewModel.addAlarm(newAlarm)
                    }
                })) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "FF8C68"))
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "FF8C68").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true)
            .background(Color(uiColor: .systemBackground)) // ✅ 다크모드 대응 (White -> Black)
        }
    }
}

#Preview {
    AlarmMenuView()
}

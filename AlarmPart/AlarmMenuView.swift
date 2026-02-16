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
                            ForEach($viewModel.alarms) { $alarm in
                                AlarmSettedView(
                                    alarm: $alarm,
                                    onDelete: {
                                        withAnimation {
                                            viewModel.firstdeleteAlarm(id: alarm.id)
                                        }
                                    },
                                    onUpdate: { updatedAlarm in
                                        viewModel.firstupdateAlarm(updatedAlarm)
                                    },
                                    // ✅ [추가] 토글 이벤트를 뷰모델에 연결
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

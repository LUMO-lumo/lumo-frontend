//
//  AlarmView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//

// 알람 메뉴가 보이는 메인 리스트 뷰

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
                    // 헤더 타이틀 (고정)
                    Text("알람 목록")
                        .font(.system(size: 24, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    // 알람 리스트 (스크롤 가능 영역)
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach($viewModel.alarms) { $alarm in
                                // AlarmSettedView에 바인딩된 알람 객체를 전달
                                AlarmSettedView(
                                    alarm: $alarm,
                                    onDelete: {
                                        // ViewModel의 삭제 로직을 호출하여 데이터와 UI 동기화
                                        withAnimation {
                                            viewModel.firstdeleteAlarm(id: alarm.id)
                                        }
                                    },
                                    onUpdate: { updatedAlarm in
                                        // 알람 수정 시 ViewModel 업데이트 호출 (데이터 일관성 유지)
                                        viewModel.firstupdateAlarm(updatedAlarm)
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 10)
                        // FAB(플로팅 버튼)가 컨텐츠를 가리지 않도록 하단 여백 확보
                        .padding(.bottom, 150)
                    }
                }
                
                // 알람 생성 버튼 (FAB)
                // [핵심] destination에 onCreate 클로저를 전달하여, 생성된 알람을 ViewModel에 추가합니다.
                NavigationLink(destination: AlarmCreate(onCreate: { newAlarm in
                    // 생성된 알람을 받아와서 뷰모델의 리스트에 추가
                    withAnimation {
                        viewModel.addAlarm(newAlarm)
                    }
                })) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "FF8C68")) // 코랄색 버튼
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "FF8C68").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 전체 화면을 꽉 채우도록 설정
            .navigationBarHidden(true)
            .background(Color.white)
        }
    }
}

#Preview {
    AlarmMenuView()
}

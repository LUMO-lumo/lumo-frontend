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
                                AlarmSettedView(alarm: $alarm, onDelete: {
                                    // 알람 삭제 로직
                                    if let index = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                        _ = withAnimation {
                                            viewModel.alarms.remove(at: index)
                                        }
                                    }
                                })
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 10)
                        // FAB(플로팅 버튼)가 컨텐츠를 가리지 않도록 하단 여백 확보
                        .padding(.bottom, 150)
                    }
                }
                
                // 알람 생성 버튼 (FAB)
                NavigationLink(destination: AlarmCreate()) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "FF8C68")) // 코랄색 버튼
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "FF8C68").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // [수정] 전체 화면을 꽉 채우도록 설정
            .navigationBarHidden(true)
            .background(Color.white)
        }
    }
}

#Preview {
    AlarmMenuView()
}

import SwiftUI
import Foundation
import AlarmKit

struct AlarmMenuView: View {
    @StateObject private var viewModel = AlarmViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {

                VStack(alignment: .leading) {
                    Text("알람 목록")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // 🚨 [핵심 수정] Binding 충돌 방지 패턴
                            // 1. 값(alarm)으로 먼저 반복문을 돌립니다.
                            ForEach(viewModel.alarms, id: \.id) { alarm in
                                // 1. 인덱스가 아니라 'ID'를 기반으로 안전한 바인딩을 만듭니다.
                                let safeBinding = Binding<Alarm>(
                                    get: {
                                        // 현재 배열에서 이 ID를 가진 알람을 찾음 (없으면 껍데기 반환하여 크래시 방지)
                                        guard let index = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) else {
                                            return alarm
                                        }
                                        return viewModel.alarms[index]
                                    },
                                    set: { newValue in
                                        // 값이 수정될 때도 ID로 다시 찾아서 업데이트
                                        if let index = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                            viewModel.alarms[index] = newValue
                                        }
                                    }
                                )

                                // 2. 위에서 만든 safeBinding을 뷰에 전달합니다.
                                AlarmSettedView(
                                    alarm: safeBinding,
                                    onDelete: {
                                        withAnimation {
                                            viewModel.firstdeleteAlarm(id: alarm.id)
                                        }
                                    },
                                    onUpdate: { updatedAlarm in
                                        viewModel.firstupdateAlarm(updatedAlarm)
                                    },
                                    onToggle: { isOn in
                                        // 바인딩에서 인덱스를 찾기 어려울 수 있으니, 여기서도 ID로 안전하게 처리
                                        if let index = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                            viewModel.toggleAlarmState(alarm: viewModel.alarms[index], isOn: isOn)
                                        }
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                                }
                        .padding(.top, 10)
                        .padding(.bottom, 150)
                    }
                }
                
                // 알람 생성 버튼
                NavigationLink(destination: AlarmCreate(onCreate: { newAlarm in
                    // 생성 시 에러 방지를 위한 딜레이 추가
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            viewModel.addAlarm(newAlarm)
                        }
                    }
                })) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF8C68"))
                            .frame(width: 60, height: 60)
                            .shadow(color: Color(hex: "FF8C68").opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

//
//  DistanceMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//
import SwiftUI
import Combine

struct DistanceMissionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: DistanceMissionViewModel
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(alarmId: Int, alarmLabel: String) {
        _viewModel = StateObject(
            wrappedValue: DistanceMissionViewModel(
                alarmId: alarmId,
                alarmLabel: alarmLabel
            )
        )
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH : mm"
        return formatter
    }
    
    var body: some View {
        ZStack{
            VStack {
                // 상단 시간 정보
                VStack(spacing: 8) {
                    Text(viewModel.alarmLabel)
                        .font(.pretendardMedium16)
                        .foregroundStyle(Color.primary)
                    
                    Text(timeFormatter.string(from: currentTime))
                        .font(.pretendardSemiBold60)
                        .foregroundStyle(Color.primary)
                        .onReceive(timer) { input in
                            currentTime = input
                        }
                }
                .padding(.top, 72)
                
                Text("거리 미션을 수행해 주세요!")
                    .font(.Body1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(Color.white)
                    .background(Color.main300, in: RoundedRectangle(cornerRadius: 6))
                    .padding(.top, 74)
                
                Spacer().frame(height:14)
                
                VStack {
                    HStack{
                        Text("목표")
                            .font(.Body1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .foregroundStyle(Color.gray500)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray500, lineWidth: 1)
                            )
                        Spacer().frame(width:10)
                        Text("\(Int(viewModel.targetDistance))m")
                            .font(.Subtitle1)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(String(format: "%.2fm", viewModel.currentDistance))
                        .font(.pretendardBold60)
                        .padding(.bottom, 30)
                        .foregroundStyle(Color.primary)
                    
                    Spacer().frame(height: 12)
                    
                    Text("움직였어요")
                        .font(.Subtitle3)
                        .foregroundStyle(Color.black)
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 54)
                .background(Color.gray200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Spacer().frame(height:74)
                
                Button(action:{
                    withAnimation {
                        viewModel.showFeedback = true
                        viewModel.isMissionCompleted = true
                        
                    }
                }) {Text("SNOOZE")}
                    .font(.Subtitle2)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .foregroundStyle(Color.primary)
                    .background(Color.gray300, in: Capsule()
                    )
                
                Spacer().frame(height:85)
                
            } .padding(.horizontal, 24)
                .blur(radius: viewModel.showFeedback ? 5 : 0)
            
            if viewModel.showFeedback {
                ZStack{
                    // 배경 (회색/검은색 반투명)
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .transition(.opacity) // 부드럽게 등장
                    
                    // 내용 (이모티콘 + 멘트)
                    VStack(spacing: 20) {
                        Image(.correct)
                            .resizable()
                            .frame(width: 180,height: 180)
                        
                        Text(viewModel.feedbackMessage)
                            .font(.Headline1)
                            .foregroundStyle(Color.main200)
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: viewModel.isMissionCompleted)
        .onAppear {
            viewModel.startDistanceMission()
        }
        .onChange(of: viewModel.isMissionCompleted) { oldValue, completed in
            if completed {
                print("🏁 거리 미션 완료! 메인 화면으로 이동합니다.")
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.currentRoot = .main
                }
            }
            
        }
    }
}

#Preview {
    DistanceMissionView(alarmId: 1, alarmLabel: "1교시 없는 날")
}

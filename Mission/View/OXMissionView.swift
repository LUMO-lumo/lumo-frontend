//
//  OXMissionView.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Combine
import SwiftUI

struct OXMissionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: OXMissionViewModel
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // UI 디자인을 위한 임의의 폰트 및 컬러 설정
    let primaryColor = Color.pink.opacity(0.8)
    
    init(alarmId: Int, alarmLabel: String) {
        _viewModel = StateObject(
            wrappedValue: OXMissionViewModel(
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
        ZStack {
            // 전체 화면 배경색 지정
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // 메인 컨텐츠
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
                
                // OX 퀴즈 컨테이너
                VStack(spacing: 0) {
                    // 미션 타이틀 배지
                    Text("OX퀴즈 미션을 수행해 주세요!")
                        .font(.Body1)
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 17)
                        .background(Color.main300, in: RoundedRectangle(cornerRadius: 6))
                        .padding(.bottom, 14)
                    
                    // 문제 영역
                    HStack {
                        Text("Q. \(viewModel.questionText)")
                            .font(.Subtitle2)
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                    .padding(24)
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray300, lineWidth: 2)
                    }
                    
                    Spacer().frame(height: 15)
                    
                    // O / X 버튼 영역
                    HStack(spacing: 10) {
                        // O 버튼
                        Button(action: {
                            viewModel.submitAnswer("O")
                        }) {
                            Text("O")
                                .font(.Subtitle1)
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 176)
                                .background(Color(hex: "E9F2FF"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "96C0FF"), lineWidth: 2)
                                )
                                .cornerRadius(16)
                        }
                        .disabled(viewModel.isLoading || viewModel.showFeedback)
                        
                        // X 버튼
                        Button(action: {
                            viewModel.submitAnswer("X")
                        }) {
                            Text("X")
                                .font(.Subtitle1)
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 176)
                                .background(Color(hex: "FFE9E6"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "F9A094"), lineWidth: 2)
                                )
                                .cornerRadius(16)
                        }
                        .disabled(viewModel.isLoading || viewModel.showFeedback)
                    }
                }
                .padding(.top, 100)
                .padding(.bottom, 205)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .blur(radius: viewModel.showFeedback || viewModel.isLoading ? 3 : 0)
            
            // 로딩 인디케이터
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            
            // 피드백 오버레이
            if viewModel.showFeedback {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Image(viewModel.isCorrect ? "correct" : "incorrect")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    
                    Text(viewModel.feedbackMessage)
                        .font(.Headline1)
                        .foregroundStyle(viewModel.isCorrect ? Color.main100 : Color.main300)
                }
                .transition(.scale)
                .zIndex(1)
            }
        }
        .onAppear {
            viewModel.startOXMission()
        }
        .onChange(of: viewModel.isMissionCompleted) { oldValue, completed in
            if completed {
                print("🏁 미션 완료! 소리를 끄고 알림을 제거합니다.")
                AlarmKitManager.shared.completeMission()
                
                withAnimation {
                    appState.currentRoot = .main
                }
            }
        }
        .alert("알림", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("확인") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    OXMissionView(alarmId: 1, alarmLabel: "1교시 있는 날")
}

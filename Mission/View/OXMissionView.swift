//
//  OXMissionView.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import SwiftUI

struct OXMissionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: OXMissionViewModel
    init(alarmId: Int = 1) {
        _viewModel = StateObject(wrappedValue: OXMissionViewModel(alarmId: alarmId))
    }
    
    var body: some View {
        ZStack{
        VStack {
                Spacer()
                
                Text("알람 정보")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.primary)
                
                
                Spacer()
                
                Text("OX퀴즈 미션을 수행해 주세요!")
                    .font(.Body1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(Color.white)
                    .background(Color.main300, in: RoundedRectangle(cornerRadius: 6))
                
                Spacer().frame(height:14)
                
                HStack {
                 Text("Q. \(viewModel.questionText)")
                        .font(.Subtitle2)
                        .foregroundStyle(Color.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray300, lineWidth: 2)
                )
                Spacer().frame(height:15)
                HStack(spacing: 10) {
                    
                    Button(action:{
                            viewModel.submitAnswer("O")
                    }){
                        Text("O")
                            .font(.Subtitle1)
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 176)
                            .background(Color(hex: "E9F2FF"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "96C0FF"), lineWidth: 2)
                            )
                    }
                    
                    Button(action:{
                            viewModel.submitAnswer("X")

                    }){
                        Text("X")
                            .font(.Subtitle1)
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 176)
                            .background(Color(hex: "FFE9E6"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "F9A094"), lineWidth: 2)
                            )
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .blur(radius: viewModel.isMissionCompleted ? 2 : 0)
            
            if viewModel.showFeedback {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Image(viewModel.isCorrect ? "correct" : "incorrect")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    
<<<<<<< HEAD
                    // 내용 (이모티콘 + 멘트)
                    VStack(spacing: 20) {
                        Image(.correct)
                            .resizable()
                            .frame(width: 180,height: 180)
                        
                        Text("정답이에요!")
                            .font(.Headline1)
                            .foregroundStyle(Color.main200)
                    }
=======
                    Text(viewModel.feedbackMessage)
                        .font(.Headline1)
                        .foregroundStyle(viewModel.isCorrect ? Color.main100 : Color.main300)
>>>>>>> e5732c2 ([feat]: 미션 테스트)
                }
                .transition(.scale)
                .zIndex(1) // 맨 앞으로 가져오기
            }
        }
        .onAppear {
            // ✅ ViewModel 내부에서 비동기 처리하므로 await 불필요
            viewModel.startOXMission()
        }
        .onChange(of: viewModel.isMissionCompleted) { oldValue, completed in
            if completed {
                print("🏁 미션 완료! 뷰를 닫습니다.")
                withAnimation {
                    appState.currentRoot = .main
                }
            }
        }
        // ✅ 에러 발생 시 알림 표시
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
    OXMissionView()
}


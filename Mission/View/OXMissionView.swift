//
//  OXMissionView.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import SwiftUI

struct OXMissionView: View {
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
                    Text("Q. 코브라끼리는 서로 물면 죽는다")
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
                        _Concurrency.Task {
                            await viewModel.submitAnswer("X")
                        }
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
                        _Concurrency.Task {
                            await viewModel.submitAnswer("X")
                        }
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
            if viewModel.isMissionCompleted {
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
                        
                        Text("정답이에요!")
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
            _Concurrency.Task {
                            await viewModel.start()
                        }
        }
        .onChange(of: viewModel.isMissionCompleted) { oldValue, newValue in
            // newValue가 true(미션 완료)가 되었을 때 실행
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    _Concurrency.Task {
                        await viewModel.dismissAlarm()
                    }
                }
            }
        }
    }
}

#Preview {
    OXMissionView()
}


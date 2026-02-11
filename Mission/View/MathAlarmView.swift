//
//  MissionView.swift
//  Lumo
//
//  Created by 김승겸 on 2/11/26.
//

import SwiftUI

struct MathAlarmView: View {
    @StateObject var viewModel: MathMissionViewModel
    
    // UI 디자인을 위한 임의의 폰트 및 컬러 설정 (Lumo 디자인 시스템에 맞춰 수정 필요)
    let primaryColor = Color.pink.opacity(0.8) // 예시 컬러
    
    init(alarmId: Int) {
        _viewModel = StateObject(wrappedValue: MathMissionViewModel(alarmId: alarmId))
    }
    
    var body: some View {
        ZStack {
            // 배경
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 상단 시간 정보
                VStack(spacing: 5) {
                    Text("1교시 있는 날")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("06 : 55") // 실제 앱에선 현재 시간 바인딩 필요
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.top, 50)
                
                // 수학 미션 컨테이너
                VStack(spacing: 0) {
                    // 미션 타이틀 배지
                    Text("수학 미션을 수행해주세요!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.orange))
                        .padding(.bottom, 20)
                    
                    // 문제 영역
                    HStack {
                        Text("Q. \(viewModel.questionText)")
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    .padding(.horizontal, 20)
                    
                    // 정답 입력 영역 (A.)
                    HStack {
                        Text("A.")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextField("답변을 입력해주세요.", text: $viewModel.userAnswer)
                            .keyboardType(.numberPad)
                            .padding(.leading, 5)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // 확인 버튼
                Button(action: {
                    viewModel.submitAnswer()
                }) {
                    Text("확인")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.gray.opacity(0.3))) // 활성화 시 색상 변경 로직 추가 가능
                }
                .padding(.bottom, 50)
            }
            .blur(radius: viewModel.showFeedback ? 3 : 0) // 피드백 시 배경 블러 처리
            
            // 피드백 오버레이 (정답/오답 화면)
            if viewModel.showFeedback {
                Color.black.opacity(0.4).ignoresSafeArea()
                
                VStack(spacing: 15) {
                    // 이모지 아이콘 (피그마의 웃는 얼굴 / 우는 얼굴)
                    Text(viewModel.isCorrect ? "🥰" : "😢")
                        .font(.system(size: 80))
                        .padding()
                        .background(Circle().fill(Color.orange.opacity(0.3)))
                    
                    Text(viewModel.feedbackMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.isCorrect ? .yellow : .red)
                }
                .transition(.scale)
            }
        }
        .onAppear {
            viewModel.startMathMission()
        }
        .onChange(of: viewModel.isMissionCompleted) { oldValue, completed in
            if completed {
                // 화면 닫기 또는 메인으로 이동 처리
                print("미션 완료! 뷰를 닫습니다.")
            }
        }
    }
}

#Preview {
    MathMissionView()
}

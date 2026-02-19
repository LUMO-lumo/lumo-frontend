//
//  TypingMission.swift
//  Lumo
//
//  Created by 김승겸 on 2/13/26.
//

import Combine
import SwiftUI

struct TypingMissionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: TypingMissionViewModel
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // UI 디자인을 위한 임의의 폰트 및 컬러 설정
    let primaryColor = Color.pink.opacity(0.8)
    
    init(alarmId: Int, alarmLabel: String) {
        _viewModel = StateObject(
            wrappedValue: TypingMissionViewModel(
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
            // ✅ 전체 화면 배경색 지정 (오버레이 시 투명 방지 & 다크모드 대응)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // 메인 컨텐츠
            VStack {
                // 상단 시간 정보
                VStack(spacing: 8) {
                    Text(viewModel.alarmLabel)
                        .font(.pretendardMedium16)
                        .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                    
                    Text(timeFormatter.string(from: currentTime))
                        .font(.pretendardSemiBold60)
                        .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                        .onReceive(timer) { input in
                            currentTime = input
                        }
                }
                .padding(.top, 72)
                
                Spacer()
                
                // 따라쓰기 미션 컨테이너
                VStack(spacing: 10){
                    // 미션 타이틀 배지
                    Text("따라쓰기 미션을 수행해주세요!")
                        .font(.Body1)
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 17)
                        .background(Color.main300, in: RoundedRectangle(cornerRadius: 6))
                        .padding(.bottom, 14)
                    
                    // 문제 영역
                    HStack {
                        Text("\(viewModel.questionText)")
                            .font(.Subtitle2)
                            .foregroundStyle(Color.primary) // ✅ 다크모드 대응
                        Spacer()
                    }
                    .padding(24)
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray300, lineWidth: 2)
                    }
                    
                    // 정답 입력 영역 (A.)
                    HStack {
                        TextField("여기에 문장을 작성해주세요", text: $viewModel.userAnswer)
                            .font(.Subtitle3)
                            .foregroundStyle(.black) // ✅ [수정] 배경이 밝은 회색이므로 글자는 항상 검은색이어야 함
                            .keyboardType(.default)
                            .multilineTextAlignment(.center)

                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 80)
                    .background(Color.gray200)
                    .cornerRadius(16)
                    .padding(.top, 10)
                    .padding(.bottom, 34)
                    .environment(\.colorScheme, .light)
                }
                
                Spacer()
                
                // 확인 버튼
                Button(action: {
                    // ✅ ViewModel 내부에서 비동기 처리하므로 await 불필요
                    viewModel.submitAnswer(viewModel.userAnswer)
                }) {
                    Text("확인")
                        .font(.Subtitle2)
                        .foregroundStyle(Color.gray700)
                        .padding(.horizontal, 27)
                        .padding(.vertical, 19)
                        .background(Color.gray300, in: RoundedRectangle(cornerRadius: 999))
                }
                .disabled(viewModel.isLoading) // 로딩 중 버튼 비활성화
                .padding(.bottom, 50)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // ✅ 로딩 인디케이터 추가
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            
            // 피드백 오버레이 (정답/오답 화면)
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
                .zIndex(1) // 맨 앞으로 가져오기
            }
        }
        // ✅ [추가] 화면 터치 시 키보드 내리기
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            viewModel.startTypingMission()
        }
        .onChange(of: viewModel.isMissionCompleted) { oldValue, completed in
            if completed {
                print("🏁 미션 완료! 소리를 끄고 알림을 제거합니다.")
                // 🔥 [핵심 수정] completeMission() 호출
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
    TypingMissionView(alarmId: 1, alarmLabel: "1교시 있는 날")
}

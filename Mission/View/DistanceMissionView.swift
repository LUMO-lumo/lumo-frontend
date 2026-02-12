import SwiftUI

struct DistanceMissionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: DistanceMissionViewModel
    
    init(alarmId: Int) {
        _viewModel = StateObject(wrappedValue: DistanceMissionViewModel(alarmId: alarmId))
    }
    var body: some View {
        ZStack{
            VStack {
                Spacer()
                
                Text("알람 정보")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                Text("거리 미션을 수행해 주세요!")
                    .font(.Body1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(Color.white)
                    .background(Color.main300, in: RoundedRectangle(cornerRadius: 6))
                
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
                        
                        AsyncTask {
                            try? await AsyncTask.sleep(nanoseconds: 1_000_000_000)
                            viewModel.isMissionCompleted = true
                            }
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
                        Image("Correct")
                            .resizable()
                            .frame(width: 180,height: 180)
                        
                        Text("잘했어요!")
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
        .onChange(of: viewModel.isMissionCompleted) { oldValue, completed in
                    if completed {
                        print("🏁 거리 미션 완료! 메인 화면으로 이동합니다.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        // 전역 루트 뷰를 메인으로 교체
                                        appState.currentRoot = .main
                                    }
                                }
                    }
                }
                // 에러 알림 처리
                .alert("알림", isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                )) {
                    Button("확인") { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
            }
        }

#Preview {
    DistanceMissionView(alarmId: 1)
}

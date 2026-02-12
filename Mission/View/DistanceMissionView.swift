//
//  DistanceMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//
import SwiftUI

struct DistanceMissionView: View {
    let alarmId: Int
    @StateObject private var viewModel: DistanceMissionViewModel
    init(alarmId: Int) {
        self.alarmId = alarmId
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
                
                Button(action:{}) {Text("SNOOZE")}
                    .font(.Subtitle2)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .foregroundStyle(Color.primary)
                    .background(Color.gray300, in: Capsule()
                    )
                
                Spacer().frame(height:85)
                
            } .padding(.horizontal, 24)
                .blur(radius: viewModel.isMissionCompleted ? 5 : 0)
            
            if viewModel.isMissionCompleted {
                ZStack{
                    // 배경 (회색/검은색 반투명)
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .transition(.opacity) // 부드럽게 등장
                    
                    // 내용 (이모티콘 + 멘트)
                    VStack(spacing: 20) {
                        Image("correct")
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
<<<<<<< HEAD
            _Concurrency.Task {
                await viewModel.start()
            }
=======
            viewModel.start()
>>>>>>> 27da3b1cde125437bac73aa2f7f23063ff9ce779
        }
        .onChange(of: viewModel.isMissionCompleted) { oldValue, newValue in
            // newValue가 true(미션 완료)가 되었을 때 실행
            if newValue {
<<<<<<< HEAD
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    _Concurrency.Task {
                        await viewModel.dismissAlarm() // 또는 dismiss()
                        
                    }
=======
                AsyncTask {
                    // 1초 대기
                    try? await AsyncTask.sleep(nanoseconds: 1_000_000_000)
                    // async 함수 호출
                    await viewModel.dismissAlarm()
>>>>>>> 27da3b1cde125437bac73aa2f7f23063ff9ce779
                }
            }
        }
    }
}

#Preview {
    DistanceMissionView(alarmId: 1)
}

//
//  MissionLevelView.swift
//  Lumo
//
//  Created by 정승윤 on 2/13/26.
//

import SwiftUI

struct MissionLevelView: View {
    @State private var viewModel = MissionLevelViewModel()
    @Environment(\.dismiss) private var dismiss

    private var sliderBinding: Binding<Int> {
            Binding(
                get: {
                    switch viewModel.selectedLevel {
                    case "LOW": return 0
                    case "MEDIUM": return 1
                    case "HIGH": return 2
                    default: return 0
                    }
                },
                set: { newValue in
                    let levels = ["LOW", "MEDIUM", "HIGH"]
                    viewModel.updateMissionLevel(level: levels[newValue])
                }
            )
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            ZStack(alignment: .leading) {
           
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.main300)
                    .opacity(0.1)
                    .frame(height: 44)
                
                HStack(spacing: 14) {
                    Image(.infocircle)
                        .resizable()
                        .frame(width:20,height:20)
                    Text("PRO 버전에서는 나에게 맞게끔 난이도를 설정할 수 있어요")
                        .font(.Body2 )
                        .foregroundStyle(Color.main300)
                }
                .padding(.horizontal, 12)
                
                
            }
            
            Text("미션 선택")
                .font(.Body1)
            
            HStack{
                Spacer()
                missionItem(image: .mathMission, title: "수학문제", size: (36, 36))
                Spacer()
                missionItem(image: .oxMission, title: "OX퀴즈", size: (41, 25))
                Spacer()
                missionItem(image: .typingMission, title: "따라쓰기", size: (42, 42))
                Spacer()
            }
            
            Text("난이도 설정")
                .font(.Body1)
            
            CustomStepSlider(selectedIndex: sliderBinding)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .topNavigationBar(title: "미션 난이도 조절 ")
        .navigationBarHidden(true)
        .onChange(of: viewModel.SmartBriefingEnabled) { oldValue, newValue in
            print("토글 상태: \(newValue)")
            viewModel.updateMissionLevel(level: String(newValue))
        }
    }
    
    @ViewBuilder
        private func missionItem(image: ImageResource, title: String, size: (CGFloat, CGFloat)) -> some View {
            VStack(spacing: 12) {
                Circle()
                    .stroke(Color.gray200, lineWidth: 1)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.white))
                    .overlay(
                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size.0, height: size.1)
                    )
                
                Text(title)
                    .font(.Body1)
                    .foregroundColor(.gray800)
            }
        }
}

#Preview {
    MissionLevelView()
}

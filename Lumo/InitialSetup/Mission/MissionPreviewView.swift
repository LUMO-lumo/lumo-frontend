//
//  MissionPreviewView.swift
//  Lumo
//
//  Created by 김승겸 on 1/6/26.
//

import SwiftUI

struct MissionPreviewView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    let missionType: MissionType
    
    var body: some View {
        VStack {
            
            HStack(spacing: 6) {
                ForEach(0..<2) { index in
                    Rectangle()
                        .foregroundStyle(Color(hex: "979DA7"))
                        .frame(height: 3)
                        .cornerRadius(999)
                }
            }
            .padding(.vertical, 10)
            
            switch missionType {
            case .math:
                MathMissionView()
            case .typing:
                TypingMissionView()
            case .distance:
                DistanceMissionView()
            case .ox:
                OxMissionView()
            }
            
            // 이전 및 다음 버튼
            HStack(spacing: 10) {
                Button(action: {
                    viewModel.path.removeLast()
                }) {
                    Text("이전")
                        .font(.Subtitle3)
                        .foregroundStyle(Color(hex: "404347"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .backgroundStyle(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
                        )
                }
                
                Button(action: {
                    viewModel.path.append(OnboardingStep.finalComplete)
                }) {
                    Text("다음")
                        .font(.Subtitle3)
                        .foregroundStyle(Color(hex: "404347"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "DDE1E8"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
                        )
                    
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

#Preview {
    MissionPreviewView(missionType: .math)
        .environment(OnboardingViewModel())
}

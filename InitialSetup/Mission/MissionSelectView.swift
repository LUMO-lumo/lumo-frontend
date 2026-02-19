//
//  MissionSelectView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//

import SwiftUI

struct MissionSelectView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    
    let columns = [
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9)
    ]
    
    var body: some View {
        VStack {
            
            Spacer() .frame(height: 37)
            
            VStack(alignment: .leading, spacing: 8) {
                // 다크모드 대응: .primary
                Text("잠에서 확실하게 깨워줄\n미션을 선택해주세요.")
                    .font(.custom("Pretendard-Bold", size: 24))
                    .foregroundStyle(.primary)
                    .lineSpacing(8)
                
                Text("나중에 변경할 수 있어요.")
                    .font(.body)
                    .foregroundStyle(Color(hex: "7A7F88"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(MissionType.allCases, id: \.self) { mission in
                    MissionButton(
                        mission: mission,
                        isSelected: viewModel.selectedMission == mission
                    ) {
                        viewModel.selectedMission = mission
                    }
                }
            }
            
            Spacer()
            
            // 다음 버튼
            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("다음")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color(hex: "404347"))
                    .background(Color(hex: "DDE1E8"))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .navigationBarBackButtonHidden(true)
    }
}

// 선택할 미션 버튼
struct MissionButton: View {
    let mission: MissionType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(getIconName(mission))
                    .resizable()
                    .scaledToFit()
                    .frame(width:96, height: 96)
                    .foregroundStyle(Color.black) // 흰 배경이므로 검은색 유지
                
                Text(mission.title)
                    .font(.body)
                    .foregroundStyle(Color.black) // 흰 배경이므로 검은색 유지
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(168/185, contentMode: .fit)
            .background(Color.white) // 배경 흰색 고정
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "F55641") : Color(hex: "DDE1E8"), lineWidth: 2)
            )
        }
    }
    
    func getIconName(_ mission: MissionType) -> String {
        switch mission {
        case .math: return "MathMission"
        case .typing: return "TypingMission"
        case .ox: return "OXMission"
        case .distance: return "DistanceMission"
        }
    }
}

#Preview {
    MissionSelectView(currentPage: .constant(0))
        .environment(OnboardingViewModel())
}

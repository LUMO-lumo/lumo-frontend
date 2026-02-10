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
    
   // private var index: Int = 0
    
    let columns = [
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9)
    ]
    
    var body: some View {
        VStack {
            
            Spacer() .frame(height: 37)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("잠에서 확실하게 깨워줄\n미션을 선택해주세요.")
                    .font(.Subtitle1)
                    .foregroundStyle(Color.black)
                    .lineSpacing(8)
                
                Text("나중에 변경할 수 있어요.")
                    .font(.Body1)
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
                        // 탭하면 뷰모델 선택값 변경
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
                    .font(.Subtitle3)
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
                    .foregroundStyle(Color.black)
                
                Text(mission.title)
                    .font(.Body1)
                    .foregroundStyle(Color.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(168/185, contentMode: .fit)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "F55641") : Color(hex: "DDE1E8"), lineWidth: 2)
            )
        }
    }
    
    // 미션별 아이콘 매핑 (임시)
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

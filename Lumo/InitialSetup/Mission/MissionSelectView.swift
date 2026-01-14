//
//  MissionSelectView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//

import SwiftUI

struct MissionSelectView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    private var index: Int = 0
    
    let columns = [
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9)
    ]
    
    var body: some View {
        VStack {
            HStack(spacing: 6) {
                ForEach(0..<2) { index in
                    Rectangle()
                        .foregroundStyle(index == 0 ? Color(hex: "F55641") : Color(hex: "DDE1E8"))
                        .frame(height: 3)
                        .cornerRadius(999)
                }
            }
            .padding(.vertical, 10)
            
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
                viewModel.path.append(OnboardingStep.missionPreview(viewModel.selectedMission))
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
                Image(systemName: getIconName(mission))
                    .resizable()
                    .scaledToFit()
                    .frame(width:72, height: 72)
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
        case .math: return "xmark.square"
        case .typing: return "xmark.square"
        case .ox: return "xmark.square"
        case .distance: return "xmark.square"
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double((rgb >>  0) & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    MissionSelectView()
        .environment(OnboardingViewModel())
}

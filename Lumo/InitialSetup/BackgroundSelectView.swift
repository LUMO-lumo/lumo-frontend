//
//  BackgroundSelectView.swift
//  Lumo
//
//  Created by 김승겸 on 1/13/26.
//

import PhotosUI
import SwiftUI

struct BackgroundSelectView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    
    let columns = [
        GridItem(.flexible() , spacing: 10),
        GridItem(.flexible() , spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .foregroundStyle(Color(hex: "F55641"))
                        .frame(height: 3)
                        .cornerRadius(999)
                }
            }
            .padding(.vertical, 10)
            
            Spacer()
            
            Text("하루의 시작을 밝혀 줄\n알람 배경을 선택해주세요.")
                .font(.Subtitle1)
            
            Spacer()
            
            LazyVGrid(columns: columns, spacing: 10) {
                
                PhotosPicker(
                    selection: Bindable(viewModel).imageSelections,
                    maxSelectionCount: 4,
                    matching: .images
                ) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .aspectRatio(168.0/230.0, contentMode: .fit)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                Text("앨범에서 선택하기")
                                    .font(.Body3)
                            }
                                .foregroundStyle(Color.black)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "D9D9D9"), lineWidth: 2)
                        )
                }
                
                // 선택된 이미지들
                ForEach(viewModel.selectedImages, id: \.self) { image in
                    Color.clear
                        .aspectRatio(168.0/230.0, contentMode: .fit)
                        .overlay(
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "DDE1E8"), lineWidth: 1)
                        )
                }
                
                if viewModel.selectedImages.count < 3 {
                    let remainingSlots = 3 - viewModel.selectedImages.count
                    ForEach(0..<remainingSlots, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(hex: "DDE1E8").opacity(0.5))
                            .aspectRatio(168.0/230.0, contentMode: .fit)
                            .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
            
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
                    viewModel.path.append(OnboardingStep.introMission)
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
        .navigationDestination(for: OnboardingStep.self) { step in
            switch step {
            case .introMission:
                MissionIntroView()
            case .missionSelect:
                MissionSelectView()
            case .missionPreview:
                MissionPreviewView()
            case .finalComplete:
                FinalCheckView()
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    BackgroundSelectView()
        .environment(OnboardingViewModel())
}

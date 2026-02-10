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
    @Binding var currentPage: Int
    
    let columns = [
        GridItem(.flexible() , spacing: 10),
        GridItem(.flexible() , spacing: 10)
    ]
    
    var body: some View {
        let body3 = Font.Body3
        let gray = Color(hex: "D9D9D9")
        
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                
                Spacer() .frame(height: 37)
                
                Text("하루의 시작을 밝혀 줄\n알람 배경을 선택해주세요.")
                    .font(.Subtitle1)
                
                Spacer() .frame(height: 45)
            }
            ScrollView {
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
                                        .font(body3)
                                }
                                    .foregroundStyle(Color.black)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(gray), lineWidth: 2)
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
                                .fill(Color(hex: "D9D9D9"))
                                .aspectRatio(168.0/230.0, contentMode: .fit)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}

#Preview {
    BackgroundSelectView(currentPage: .constant(4))
        .environment(OnboardingViewModel())
}

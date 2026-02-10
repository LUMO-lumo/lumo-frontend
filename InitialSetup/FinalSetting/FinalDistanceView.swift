//
//  FinalDistanceView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalDistanceView: View {
    var body: some View {
        VStack {
            Text("거리 미션을 수행해주세요!")
                .font(.Body1)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "F55641"))
                .cornerRadius(6.33)
                
            VStack {
                HStack(spacing: 10) {
                    Text("목표")
                        .font(.Body1)
                        .foregroundStyle(Color(hex: "979DA7"))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "979DA7"), lineWidth: 1)
                        )
                    
                    Text("100m")
                        .font(.Subtitle1)
                        .foregroundStyle(Color.black)
                }
                
                Text("0.00m")
                    .font(.pretendardBold60)
                    .foregroundStyle(Color.black)
                
                Text("움직였어요")
                    .font(.Subtitle3)
                   
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 80)
            .background(Color(hex: "F2F4F7"))
            .cornerRadius(16)
            
            Spacer()
        }
    }
}

#Preview {
    FinalDistanceView()
}

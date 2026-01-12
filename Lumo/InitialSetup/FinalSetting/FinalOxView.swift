//
//  FinalOxView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalOxView: View {
    var body: some View {
        VStack {
            Text("OX퀴즈 미션을 수행해주세요!")
            
                .font(.Body1)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "F55641"))
                .cornerRadius(6.33)
            
            HStack(spacing: 4) {
                Text("Q.")
                    .font(.pretendardSemiBold14)
                    .foregroundStyle(Color.black)
                Text("코브라끼리는 서로 물면 죽는다")
                    .font(.pretendardSemiBold14)
                    .foregroundStyle(Color.black)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.white)
            .cornerRadius(12.65)
            .overlay(
                RoundedRectangle(cornerRadius: 12.65)
                    .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
            )
            
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "E9F2FF"))
                    .aspectRatio(167.0/176.0, contentMode: .fit)
                    .overlay(
                        Text("O")
                            .font(.Subtitle1)
                            .foregroundStyle(Color.black)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "96C0FF"), lineWidth: 2)
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "FFE9E6"))
                    .aspectRatio(167.0/176.0, contentMode: .fit)
                    .overlay(
                        Text("X")
                            .font(.Subtitle1)
                            .foregroundStyle(Color.black)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "F9A094"), lineWidth: 2)
                    )
            }
            
            Spacer()
        }
    }
}

#Preview {
    FinalOxView()
}

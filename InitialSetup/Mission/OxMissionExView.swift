//
//  OxMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//
import SwiftUI

struct OxMissionExView: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Text("\(Text("OX퀴즈").foregroundStyle(Color(hex: "F55641")))는 이런 미션을 수행해요")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.black)
            }
            
            Spacer()
            
            HStack {
                Text("Q. 코브라끼리는 서로 물면 죽는다")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.black)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
            )
            
            HStack(spacing: 10) {
                Text("O")
                    .font(.Subtitle1)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 176)
                    .background(Color(hex: "E9F2FF"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "96C0FF"), lineWidth: 2)
                    )
                
                Text("X")
                    .font(.Subtitle1)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 176)
                    .background(Color(hex: "FFE9E6"))
                    .cornerRadius(16)
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
    OxMissionExView()
}

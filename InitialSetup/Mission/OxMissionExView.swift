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
                // 다크모드 대응: .primary
                Text("\(Text("OX퀴즈").foregroundStyle(Color(hex: "F55641")))는 이런 미션을 수행해요")
                    .font(.custom("Pretendard-Bold", size: 24))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            HStack {
                // 다크모드 대응: .primary
                Text("Q. 코브라끼리는 서로 물면 죽는다")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
            )
            
            HStack(spacing: 10) {
                // 배경색이 있으므로 Black 유지
                Text("O")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 176)
                    .background(Color(hex: "E9F2FF"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "96C0FF"), lineWidth: 2)
                    )
                
                // 배경색이 있으므로 Black 유지
                Text("X")
                    .font(.system(size: 30, weight: .bold))
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

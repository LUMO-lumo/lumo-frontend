//
//  MathMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//

import SwiftUI

struct MathMissionExView: View {
    var body: some View {
        VStack {
            Spacer()
            
            // 다크모드 대응: .primary
            Text("\(Text("수학 미션").foregroundStyle(Color(hex: "F55641")))은 이런 미션을 수행해요")
                .font(.custom("Pretendard-Bold", size: 24))
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack {
                // 다크모드 대응: .primary
                Text("Q. 88+33 = ?")
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
            
            VStack {
                HStack {
                    // 밝은 회색 배경 위이므로 Black 유지
                    Text("A. \(Text("답변을 입력해주세요.").foregroundStyle(Color(hex: "979DA7")))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.black)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 274)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .background(Color(hex: "F2F4F7"))
            .cornerRadius(16)
            
            Spacer()
        }
    }
}

#Preview {
    MathMissionExView()
}

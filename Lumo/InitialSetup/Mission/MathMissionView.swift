//
//  MathMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//

import SwiftUI

struct MathMissionView: View {
    var body: some View {
        VStack {
            Spacer()
            
                Text("\(Text("수학 미션").foregroundStyle(Color(hex: "F55641")))은 이런 미션을 수행해요")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.black)
            
            Spacer()
            
            HStack {
                Text("Q. 88+33 = ?")
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
            
            VStack {
                HStack {
                    Text("A. \(Text("답변을 입력해주세요.").foregroundStyle(Color(hex: "979DA7")))")
                        .font(.Subtitle2)
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
    MathMissionView()
}

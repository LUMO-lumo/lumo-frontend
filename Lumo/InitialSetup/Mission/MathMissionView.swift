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
            
            HStack {
                Text("수학 미션")
                    .font(.Subtitle2)
                    .foregroundStyle(Color(hex: "F55641"))
                + Text("은 이런 미션을 수행해요")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.black)
            }
            
            Spacer()
            
            HStack {
                Text("Q.")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.black)
                
                + Text(" 88+33 = ?")
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
                    Text("A.")
                        .font(.Subtitle2)
                        .foregroundStyle(Color.black)
                    + Text(" 답변을 입력해주세요.")
                        .font(.Subtitle3)
                        .foregroundStyle(Color(hex: "979DA7"))
                    
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

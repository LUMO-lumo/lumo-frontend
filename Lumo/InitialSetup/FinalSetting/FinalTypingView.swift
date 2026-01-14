//
//  FinalTypingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalTypingView: View {
    var body: some View {
        VStack {
            Text("따라쓰기 미션을 수행해주세요!")
            
                .font(.Body1)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "F55641"))
                .cornerRadius(6.33)
                
            HStack {
                
                Text("할 수 있다!")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.black)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.white)
            .cornerRadius(12.65)
            .overlay(
                RoundedRectangle(cornerRadius: 12.65)
                    .stroke(Color(hex: "DDE1E8"), lineWidth: 1)
            )
            
            Text("여기에 문장을 작성해 주세요")
                .font(.Subtitle3)
                .foregroundStyle(Color(hex: "979DA7"))
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
    FinalTypingView()
}

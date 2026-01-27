//
//  TypingMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//
import SwiftUI

struct TypingMissionView: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Text("\(Text("따라쓰기").foregroundStyle(Color(hex: "F55641")))는 이런 미션을 수행해요")
                    .font(.Subtitle2)
                    .foregroundStyle(Color.black)
            }
            
            Spacer()
            
            HStack {
                Text("할 수 있다!")
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
    TypingMissionView()
}

//
//  FinalTypingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalTypingView: View {
    @Environment(\.colorScheme) var scheme

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
                    .foregroundStyle(scheme == .dark ? .white : .black)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            // 박스 배경: 다크모드 대응
            .background(scheme == .dark ? Color(hex: "2C2C2E") : Color.white)
            .cornerRadius(12.65)
            .overlay(
                RoundedRectangle(cornerRadius: 12.65)
                    .stroke(scheme == .dark ? Color.gray.opacity(0.3) : Color(hex: "DDE1E8"), lineWidth: 1)
            )
            
            Text("여기에 문장을 작성해 주세요")
                .font(.Subtitle3)
                .foregroundStyle(Color(hex: "979DA7"))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 80)
                // 입력 박스 배경: 다크모드 대응
                .background(scheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "F2F4F7"))
                .cornerRadius(16)
            
            Spacer()
        }
    }
}

#Preview {
    FinalTypingView()
}

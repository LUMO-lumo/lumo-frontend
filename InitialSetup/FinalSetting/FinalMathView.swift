//
//  FinalMathView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalMathView: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack {
            Text("수학 미션을 수행해주세요!")
                .font(.pretendardSemiBold12)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "F55641"))
                .cornerRadius(6.33)
            
            HStack {
                Text("Q. 88+33 = ?")
                    .font(.pretendardSemiBold14)
                    .foregroundStyle(scheme == .dark ? .white : .black)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            // 박스 배경: 다크모드 대응
            .background(scheme == .dark ? Color(hex: "2C2C2E") : Color.white)
            .cornerRadius(12.65)
            .overlay(
                RoundedRectangle(cornerRadius: 12.65)
                    .stroke(scheme == .dark ? Color.gray.opacity(0.3) : Color(hex: "DDE1E8"), lineWidth: 1)
            )
            
            VStack {
                HStack {
                    Text("A. ")
                        .font(.pretendardSemiBold14)
                        .foregroundStyle(scheme == .dark ? .white : .black)
                    Text("답변을 입력해주세요.")
                        .font(.pretendardSemiBold14)
                        .foregroundStyle(Color(hex: "979DA7"))
                    
                    Spacer()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            // 입력 박스 배경: 다크모드 대응
            .background(scheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "F2F4F7"))
            .cornerRadius(16)
            
            Spacer()
        }
    }
}

#Preview {
    FinalMathView()
}

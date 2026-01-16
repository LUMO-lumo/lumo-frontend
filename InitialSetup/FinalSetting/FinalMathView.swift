//
//  FinalMathView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalMathView: View {
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
                    .foregroundStyle(Color.black)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.white)
            .cornerRadius(12.65)
            .overlay(
                RoundedRectangle(cornerRadius: 12.65)
                    .stroke(Color(hex: "DDE1E8"), lineWidth: 1)
            )
            
            VStack {
                HStack {
                    Text("A. \(Text("답변을 입력해주세요.").foregroundStyle(Color(hex: "979DA7")))")
                        .font(.pretendardSemiBold14)
                        .foregroundStyle(Color.black)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color(hex: "F2F4F7"))
            .cornerRadius(16)
            
            Spacer()
        }
    }
}

#Preview {
    FinalMathView()
}

//
//  FinalOxView.swift
//  Lumo
//
//  Created by 김승겸 on 1/12/26.
//

import SwiftUI

struct FinalOxView: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack {
            Text("OX퀴즈 미션을 수행해주세요!")
                .font(.Body1)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "F55641"))
                .cornerRadius(6.33)
            
            HStack(spacing: 4) {
                Text("Q.")
                    .font(.pretendardSemiBold14)
                    .foregroundStyle(scheme == .dark ? .white : .black)
                Text("코브라끼리는 서로 물면 죽는다")
                    .font(.pretendardSemiBold14)
                    .foregroundStyle(scheme == .dark ? .white : .black)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            // 질문 박스 배경: 다크모드 대응
            .background(scheme == .dark ? Color(hex: "2C2C2E") : Color.white)
            .cornerRadius(12.65)
            .overlay(
                RoundedRectangle(cornerRadius: 12.65)
                    .stroke(scheme == .dark ? Color.gray.opacity(0.3) : Color(hex: "DDE1E8"), lineWidth: 2)
            )
            
            HStack(spacing: 10) {
                // O 버튼 (배경색은 파스텔톤이라 그대로 유지해도 가독성 양호)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "E9F2FF"))
                    .aspectRatio(167.0/176.0, contentMode: .fit)
                    .overlay(
                        Text("O")
                            .font(.Subtitle1)
                            .foregroundStyle(Color.black)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "96C0FF"), lineWidth: 2)
                    )
                
                // X 버튼
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "FFE9E6"))
                    .aspectRatio(167.0/176.0, contentMode: .fit)
                    .overlay(
                        Text("X")
                            .font(.Subtitle1)
                            .foregroundStyle(Color.black)
                    )
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
    FinalOxView()
}

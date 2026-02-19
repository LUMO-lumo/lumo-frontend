//
//  TypingMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//
import SwiftUI

struct TypingMissionExView: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                // 다크모드 대응: .primary
                Text("\(Text("따라쓰기").foregroundStyle(Color(hex: "F55641")))는 이런 미션을 수행해요")
                    .font(.custom("Pretendard-Bold", size: 24))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            HStack {
                // 다크모드 대응: .primary
                Text("할 수 있다!")
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
            
            // 밝은 회색 배경 위이므로 회색 텍스트 유지 (다크모드에서도 잘 보임)
            Text("여기에 문장을 작성해 주세요")
                .font(.system(size: 20, weight: .bold))
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
    TypingMissionExView()
}

//
//  DistanceMissionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/5/26.
//
import SwiftUI

struct DistanceMissionExView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("\(Text("거리 미션").foregroundStyle(Color(hex: "F55641")))은 이런 미션을 수행해요")
                .font(.Subtitle2)
                .foregroundStyle(Color.black)
            
            Spacer()
            
            HStack {
                Text("움직일 거리를 설정해주세요")
                    .font(.pretendardMedium16)
                Spacer()
            }
            
            HStack {
                Text("100")
                    .font(.Subtitle3)
                    .foregroundStyle(Color.black)
                
                Spacer()
                
                Text("m")
                    .font(.Subtitle3)
                    .foregroundStyle(Color(hex: "979DA7"))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "DDE1E8"), lineWidth: 2)
            )
            VStack {
                Text("0.00m")
                    .font(.pretendardBold60)
                    .padding(.bottom, 30)
                    .foregroundStyle(Color.black)
                
                Spacer().frame(height: 12)
                
                Text("움직였어요")
                    .font(.Subtitle3)
                    .foregroundStyle(Color.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 54)
            .background(Color(hex: "F2F4F7"))
            .cornerRadius(16)
            
            Spacer()
        }
    }
}

#Preview {
    DistanceMissionExView()
}

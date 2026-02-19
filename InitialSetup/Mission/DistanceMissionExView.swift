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
            
            // 다크모드 대응: .primary 사용
            Text("\(Text("거리 미션").foregroundStyle(Color(hex: "F55641")))은 이런 미션을 수행해요")
                .font(.custom("Pretendard-Bold", size: 24)) // 폰트가 없을 경우를 대비해 임시 시스템 폰트 대체 가능
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack {
                Text("움직일 거리를 설정해주세요")
                    .font(.system(size: 16, weight: .medium)) // .pretendardMedium16 대체
                Spacer()
            }
            
            HStack {
                // 투명 배경 위 텍스트이므로 다크모드 대응 필요 (.primary)
                Text("100")
                    .font(.system(size: 20, weight: .bold)) // .Subtitle3 대체
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("m")
                    .font(.system(size: 20, weight: .bold)) // .Subtitle3 대체
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
                // 밝은 회색(F2F4F7) 배경 위이므로 다크모드여도 Black 유지
                Text("0.00m")
                    .font(.system(size: 60, weight: .bold)) // .pretendardBold60 대체
                    .padding(.bottom, 30)
                    .foregroundStyle(Color.black)
                
                Spacer().frame(height: 12)
                
                Text("움직였어요")
                    .font(.system(size: 20, weight: .bold)) // .Subtitle3 대체
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

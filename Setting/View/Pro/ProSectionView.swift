//
//  ProSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//
import SwiftUI

struct ProSectionView: View {
    var body: some View {
        VStack(alignment: .leading ,spacing: 32) {
            Text("PRO 업그레이드")
                .font(.Subtitle3)
                .foregroundStyle(Color.black)
            
//            Spacer()
            
            NavigationLink(destination: Text("미션 난이도 조정")) {
                HStack {
                    Text("미션 난이도 조정")
                        .font(.Body1)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image("chevronRight")
                        .foregroundColor(.gray500)
                }
            }
            
//            Spacer()
            
            NavigationLink(destination: Text("미션 난이도 조정")) { // 나중에 LoginView()로 교체
                HStack {
                    Text("스마트 브리핑")
                        .font(.Body1)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image("chevronRight")
                        .foregroundColor(.gray500)
                }
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.gray300, lineWidth: 1)
        )
    }
}
    
#Preview {
    ProSectionView()
}

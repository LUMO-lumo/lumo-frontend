//
//  AdvancedSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//
import SwiftUI

struct AdvancedSectionView: View {
    var body: some View {
        VStack(alignment: .leading ,spacing: 32) {
            Text("고급 설정")
                .font(.Subtitle3)
                .foregroundStyle(Color.primary)
            
            
            NavigationLink(destination: Text("화면 테마 설정")) {
                HStack {
                    Text("화면 테마")
                        .font(.Body1)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image("chevronRight")
                        .foregroundStyle(Color.gray500)
                }
            }
            
            NavigationLink(destination: Text("미션 알람 설정")) {
                HStack {
                    Text("미션 알람 설정")
                        .font(.Body1)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Image("chevronRight")
                        .foregroundStyle(Color.gray500)
                }
            }
            
            NavigationLink(destination: Text("브리핑 목소리 설정")) {
                HStack {
                    Text("브리핑 목소리 설정")
                        .font(.Body1)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Image("chevronRight")
                        .foregroundStyle(Color.gray500)
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
    AdvancedSectionView()
}

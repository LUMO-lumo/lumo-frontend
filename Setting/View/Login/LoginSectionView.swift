//
//  LoginSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//
import SwiftUI

struct LoginSectionView : View {
    var body: some View {
        // 로그인 섹션
        HStack(spacing: 13) {
            // 프로필 이미지 (기본 이미지, 클릭 X)
            Circle()
                .frame(width: 42, height: 42)
                .foregroundColor(.gray300)
            
            
            NavigationLink(destination: Text("로그인 화면")) { // 나중에 LoginView()로 교체
                HStack {
                    Text("로그인이 필요해요")
                        .font(.Subtitle2)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Image("chevronRight")
                        .foregroundColor(.gray500)
                }
            }
        }
        .padding(.top, 9)
    }
}

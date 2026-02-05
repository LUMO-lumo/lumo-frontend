//
//  LoginSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//

import SwiftUI

struct LoginSectionView: View {
    @Binding var isTabBarHidden: Bool
    
    // 상위 뷰에서 전달받은 유저 데이터
    let user: UserModel?
    
    // 토큰 존재 여부 확인 (Computed Property)
    // KeychainManager에 저장된 "accessToken"이 있으면 true
    private var isLoggedIn: Bool {
        return KeychainManager.shared.read(for: "accessToken") != nil
    }
    
    var body: some View {
        // 로그인 섹션
        HStack(spacing: 13) {
            // 1. 프로필 이미지 (공통)
            Circle()
                .frame(width: 42, height: 42)
                .foregroundStyle(Color.gray300)
            
            // 2. 텍스트 및 이동 로직 분기
            if let user = user, isLoggedIn {
                // 로그인 된 경우: 닉네임 표시 & 이동 로직 없음
                HStack {
                    Text(user.nickname) // 저장된 닉네임 표시
                        .font(.Subtitle2)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    // 이동 로직이 없으므로 화살표(Chevron)도 숨김 (필요하면 추가 가능)
                }
            } else {
                // 로그인 안 된 경우: "로그인이 필요해요" & 로그인 화면 이동
                NavigationLink(destination: LoginView(isTabBarHidden: $isTabBarHidden)) {
                    HStack {
                        Text("로그인이 필요해요")
                            .font(.Subtitle2)
                            .foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                        Image("chevronRight")
                            .foregroundStyle(Color.gray500)
                    }
                }
            }
        }
        .padding(.top, 9)
    }
}

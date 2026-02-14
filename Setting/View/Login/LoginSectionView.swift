//
//  LoginSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//

import Foundation
import SwiftData
import SwiftUI

struct LoginSectionView: View {
    
    @Binding var isTabBarHidden: Bool
    
    /// 상위 뷰에서 전달받은 유저 데이터
    let user: UserModel?
    
    /// 토큰 존재 여부 확인: KeychainManager에 저장된 "userSession"이 있으면 true
        private var isLoggedIn: Bool {
            // 수정됨: loadSession이 throws를 하므로 try?를 사용하여 에러 발생 시 nil로 처리
            // (try? 결과가 nil이 아니면 토큰이 존재한다는 뜻)
            return (try? KeychainManager.standard.loadSession(for: "userSession")) != nil
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
                // 로그인 된 경우: 닉네임 표시
                HStack {
                    Text(user.nickname)
                        .font(.Subtitle2)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
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

#Preview {
    LoginSectionView(isTabBarHidden: .constant(false), user: nil)
        .modelContainer(for: UserModel.self, inMemory: true)
}

//
//  ETCSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//

import SwiftData
import SwiftUI

struct ETCSectionView: View {
    
    @Binding var isTabBarHidden: Bool
    
    // 로그아웃 상태 관리 (필요시 바인딩으로 연결)
    @Environment(\.modelContext) private var modelContext
    
    let user: UserModel?
    
    // 로그인 상태 확인 (유저 정보 있음 + 토큰 있음)
    private var isLoggedIn: Bool {
        return user != nil && KeychainManager.shared.read(for: "accessToken") != nil
    }
    
    var body: some View {
        HStack(spacing: 30) {
            
            NavigationLink(destination: Text("공지사항")) {
                Text("공지사항")
                    .font(.Body2)
                    .foregroundStyle(Color.gray700)
            }
            
            NavigationLink(destination: Text("의견 보내기")) {
                Text("의견 보내기")
                    .font(.Body2)
                    .foregroundStyle(Color.gray)
            }
            
            // 상태에 따라 버튼(로그아웃) vs 링크(로그인) 분기
            if isLoggedIn {
                // 로그인 상태 -> 로그아웃 버튼
                Button(action: {
                    if let user = user {
                        logout(user: user)
                    }
                }) {
                    Text("로그아웃")
                        .font(.Body2)
                        .foregroundStyle(Color.main300)
                        .underline()
                }
            } else {
                // 비로그인 상태 -> 로그인 화면 이동 링크
                NavigationLink(
                    destination: LoginView(isTabBarHidden: $isTabBarHidden)
                ) {
                    Text("로그인")
                        .font(.Body2)
                        .foregroundStyle(Color.main300)
                        .underline()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    /// 로그아웃 처리
    private func logout(user: UserModel) {
        // 1. 키체인에서 토큰 삭제 (보안)
        KeychainManager.shared.delete(for: "accessToken")
        
        // 2. SwiftData에서 유저 정보 삭제 (UI 자동 업데이트 트리거)
        modelContext.delete(user)
        
        print("로그아웃 완료: 데이터 삭제됨")
    }
}

#Preview {
    ETCSectionView(isTabBarHidden: .constant(false), user: nil)
}

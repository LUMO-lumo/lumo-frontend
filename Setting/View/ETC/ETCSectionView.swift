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
    
    // 로그아웃 상태 관리
    @Environment(\.modelContext) private var modelContext
    @State private var showLogoutAlert = false // Alert 표시 여부
    
    let user: UserModel?
    
    // 로그인 상태 확인: 유저 정보 있음 + 토큰 있음
    private var isLoggedIn: Bool {
        // 수정됨: loadSession이 throws하므로 try? 사용
        // (try? 결과가 nil이 아니면 토큰이 있다는 뜻)
        user != nil && (try? KeychainManager.standard.loadSession(for: "userSession")) != nil
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
                // 로그인 상태 -> 로그아웃 버튼 (Alert 띄우기)
                Button(action: {
                    showLogoutAlert = true
                }) {
                    Text("로그아웃")
                        .font(.Body2)
                        .foregroundStyle(Color.main300)
                        .underline()
                }
                .alert("로그아웃 하시겠어요?", isPresented: $showLogoutAlert) {
                    Button("아니요", role: .cancel) { }
                    Button("네", role: .destructive) {
                        if let user = user {
                            logout(user: user)
                        }
                    }
                } message: {
                    Text("로그아웃 상태에서 이용 시 개인정보가 저장되지 않아요. 저장하려면 로그인해주세요.")
                        .font(.Body3)
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
    
    /// 실제 로그아웃 처리 로직
    private func logout(user: UserModel) {
        // 1. 키체인에서 토큰 삭제 (수정됨: try? 사용)
        // 삭제 실패 에러는 로그아웃 과정에서 크게 중요하지 않으므로 무시해도 무방함
        try? KeychainManager.standard.deleteSession(for: "userSession")
        
        // 2. SwiftData에서 유저 정보 삭제
        modelContext.delete(user)
        
        print("✅ 로그아웃 완료: 데이터 삭제됨")
    }
}

#Preview {
    // Preview를 위한 더미 데이터 필요 시 수정 가능
    ETCSectionView(isTabBarHidden: .constant(false), user: nil)
}

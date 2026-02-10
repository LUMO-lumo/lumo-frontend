//
//    ETCSectionView.swift
//    Lumo
//
//    Created by 김승겸 on 1/30/26.
//

import SwiftData
import SwiftUI

struct ETCSectionView: View {
<<<<<<< HEAD
    
    @Binding var isTabBarHidden: Bool
    
    // 로그아웃 상태 관리
    @Environment(\.modelContext) private var modelContext
    
    let user: UserModel?
    
    // 로그인 상태 확인: 유저 정보 있음 + 토큰 있음
    private var isLoggedIn: Bool {
        user != nil && KeychainManager.standard.loadSession(for: "userSession") != nil
    }
=======
    // 로그아웃 상태 관리 (필요시 바인딩으로 연결)
    @State private var isLoggedIn: Bool = true
    @State private var LogoutAlert = false
>>>>>>> origin/test/merge-check
    
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
            
<<<<<<< HEAD
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
=======
            Button(action: {
                LogoutAlert = true
                print("로그아웃 탭")
            }) {
                Text(isLoggedIn ? "로그아웃" : "로그인")
                    .font(.Body2)
                    .foregroundStyle(Color.main300)
                    .underline()
>>>>>>> origin/test/merge-check
            }
        }
        .alert("로그아웃 하시겠어요?", isPresented: $LogoutAlert) {
                Button("아니요", role: .cancel) { }
                Button("네") {
                    print("로그아웃 시도")
                }
            } message: {
                Text("로그아웃 상태에서 이용 시 개인정보가 저장되지 않아요. 저장하려면 로그인해주세요.")
                    .font(.Body3)
        }
        .frame(maxWidth: .infinity)
    }
    
<<<<<<< HEAD
    /// 로그아웃 처리
    private func logout(user: UserModel) {
        // 1. 키체인에서 토큰 삭제
        KeychainManager.standard.deleteSession(for: "userSession")
        
        // 2. SwiftData에서 유저 정보 삭제
        modelContext.delete(user)
        
        print("로그아웃 완료: 데이터 삭제됨")
    }
=======
>>>>>>> origin/test/merge-check
}

#Preview {
    ETCSectionView(isTabBarHidden: .constant(false), user: nil)
}

//
//  ETCSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//
import SwiftUI

struct ETCSectionView: View {
    // 로그아웃 상태 관리 (필요시 바인딩으로 연결)
    @State private var isLoggedIn: Bool = true
    @State private var LogoutAlert = false
    
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
            
            Button(action: {
                LogoutAlert = true
                print("로그아웃 탭")
            }) {
                Text(isLoggedIn ? "로그아웃" : "로그인")
                    .font(.Body2)
                    .foregroundStyle(Color.main300)
                    .underline()
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
    
}

#Preview {
    ETCSectionView()
}

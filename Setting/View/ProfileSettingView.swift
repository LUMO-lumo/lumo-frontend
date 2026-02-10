//
//  ProfileSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/29/26.
//

import SwiftData
import SwiftUI

struct ProfileSettingView: View {
    
    @Binding var isTabBarHidden: Bool
    
    @Query private var users: [UserModel]
    
    /// 현재 로그인된 유저 (없으면 nil)
    private var currentUser: UserModel? {
        return users.first
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("프로필 설정")
                    .padding(.horizontal, 16)
                    .font(.system(size: 20, weight: .bold))
                
                VStack {
                    LoginSectionView(
                        isTabBarHidden: $isTabBarHidden,
                        user: currentUser
                    )
                    
                    ProSectionView()
                    
                    Spacer()
                        .frame(height: 16)
                    
                    AdvancedSectionView()
                    
                    Spacer()
                        .frame(height: 16)
                    
                    SupportSectionView()
                    
                    Spacer()
                        .frame(height: 20)
                    
                    ETCSectionView(
                        isTabBarHidden: $isTabBarHidden,
                        user: currentUser
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 87)
                .onAppear {
                    isTabBarHidden = false
                }
            }
        }
    }
}

#Preview {
    ProfileSettingView(isTabBarHidden: .constant(false))
}

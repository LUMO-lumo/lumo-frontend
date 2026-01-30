//
//  ProfileSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/29/26.
//

import SwiftUI

struct ProfileSettingView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("프로필 설정")
                    .padding(.horizontal, 16)
                    .font(.system(size: 20, weight: .bold))
                
                
                VStack {
                    
                    LoginSectionView()
                    
                    ProSectionView()
                    
                    Spacer() .frame(height: 16)
                    
                    AdvancedSectionView()
                    
                    Spacer() .frame(height: 16)
                    
                    SupportSectionView()
                    
                    Spacer() .frame(height: 20)
                    
                    ETCSectionView()
                    
                }
                .padding(.top, 8)
                .padding(.bottom, 87)
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    ProfileSettingView()
}



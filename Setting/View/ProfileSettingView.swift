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
                    .padding(.vertical, 8)
                    .font(.system(size: 20, weight: .bold))
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        LoginSectionView()
                        
                        ProSectionView()
                        
                        
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    ProfileSettingView()
}



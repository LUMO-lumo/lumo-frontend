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
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Image("chevronRight")
                                        .foregroundColor(.gray500)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 17)
                        
                        // 여기에 추후 [PRO 업그레이드], [고급 설정] 등이 추가됩니다.
                        
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileSettingView()
}



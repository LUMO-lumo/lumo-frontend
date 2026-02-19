//
//  TopNavigationBar.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation
import SwiftUI

struct TopNavigationBar: ViewModifier {
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // 커스텀 상단 바 영역
            ZStack {
                // 중앙 타이틀
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                // 좌측 뒤로가기 버튼
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .background(Color(uiColor: .systemBackground))
            
            // 바와 콘텐츠 사이의 간격
            Spacer().frame(height: 32)
            
            // 실제 뷰 콘텐츠
            content
        }
    }
}

extension View {
    func topNavigationBar(title: String) -> some View {
        self.modifier(TopNavigationBar(title: title))
    }
}

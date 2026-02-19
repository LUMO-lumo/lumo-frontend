//
//  ScreenThemeSettingView.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import SwiftUI

struct ScreenThemeSettingView: View {
    @State private var viewModel = ScreenThemeSettingViewModel()
    @AppStorage("userTheme") private var userTheme: String = "SYSTEM"
    @Environment(\.dismiss) private var dismiss
    
    let options = ["LIGHT", "DARK", "SYSTEM"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(options, id: \.self) { theme in
                    themeRow(for: theme)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
        .topNavigationBar(title: "화면 테마 설정")
        .navigationBarHidden(true)
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func themeRow(for theme: String) -> some View {
        Button(action: {
            userTheme = theme
            viewModel.updateTheme(theme: theme)
        }) {
            HStack(spacing: 16) {
                // 테마 아이콘 이미지
                Image(getThemeImageName(for: theme))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 테마 이름
                Text(getThemeDisplayName(for: theme))
                    .foregroundColor(.primary)
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                // 커스텀 라디오 버튼
                selectionIndicator(isSelected: userTheme == theme)
            }
            .padding(.vertical, 5)
        }
    }
    
    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.main300 : Color.gray, lineWidth: 1)
                .frame(width: 16, height: 16)
            
            if isSelected {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.main300)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getThemeImageName(for theme: String) -> String {
        switch theme {
        case "LIGHT": return "ThemeLight"
        case "DARK":  return "ThemeDark"
        default:      return "ThemeSystem"
        }
    }
    
    private func getThemeDisplayName(for theme: String) -> String {
        switch theme {
        case "LIGHT": return "라이트 모드"
        case "DARK":  return "다크 모드"
        default:      return "시스템 모드"
        }
    }
}

#Preview {
    ScreenThemeSettingView()
}

//
//  ScreenThemeSettingView.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//
import SwiftUI

struct ScreenThemeSettingView: View {
    @State private var viewModel = ScreenThemeSettingViewModel()
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userTheme") private var userTheme: String = "system"
    let options = ["Light", "Dark", "System"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
        List {
            ForEach(options, id: \.self) { theme in
                Button(action: {
                    userTheme = theme
                    viewModel.updateTheme(theme: theme)
                }) {
                    HStack(spacing: 10) {
                        Image(theme == "Light" ? "ThemeLight" : (theme == "Dark" ? "ThemeDark" : "ThemeSystem"))
                            .resizable()
                            .scaledToFill()
                            .frame(width:60, height:60)
                              
                        Text(theme == "Light" ? "라이트 모드" : (theme == "Dark" ? "다크 모드" : "시스템 모드"))
                            .foregroundColor(.primary)
                            .font(.system(size: 18, weight: .bold))
                        
                        Spacer()
                        
                        ZStack{
                            Circle()
                                .stroke(userTheme == theme ? Color.main300 : Color.gray, lineWidth: 1)
                                .frame(width:16, height:16)
                                .foregroundColor(.main300)
                            if userTheme == theme {
                                Circle()
                                    .frame(width:8, height:8)
                                    .foregroundColor(.main300)
                            }
                        }
                    }
                    Spacer().frame(height:10)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
    .navigationBarTitleDisplayMode(.inline)
    .topNavigationBar(title: "화면 테마 설정")
    .navigationBarHidden(true)
    }
}

#Preview {
    ScreenThemeSettingView()
}

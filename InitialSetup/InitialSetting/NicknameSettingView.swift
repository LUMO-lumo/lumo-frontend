//
//  NicknameSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

import SwiftUI

struct NicknameSettingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Environment(\.colorScheme) var scheme
    @Binding var currentPage: Int
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("닉네임을 설정해주세요.")
                .font(.Subtitle1)
                // 다크모드 대응
                .foregroundStyle(scheme == .dark ? .white : .black)
                .padding(.top, 37)
            
            Text("알려주신 이름으로 알람을 보내드릴게요.")
                .font(.Body1)
                .foregroundStyle(scheme == .dark ? Color.gray400 : Color(hex: "7A7F88"))
                .padding(.bottom, 57)
            
            // 닉네임 입력 필드
            VStack(spacing: 8) {
                TextField("닉네임을 입력해주세요", text: Bindable(viewModel).nickname)
                    .font(.Subtitle1)
                    .foregroundStyle(scheme == .dark ? .white : .black) // 입력 텍스트 색상
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.vertical, 10)
                    .onChange(of: viewModel.nickname) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "tempNickname")
                        print("📝 닉네임 입력 중: \(newValue) 저장됨")
                    }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(scheme == .dark ? Color.gray600 : Color(hex: "DDE1E8"))
            }
            
            Spacer()
        }
        .onTapGesture {
            isFocused = false
        }
        .onChange(of: currentPage) { _, newValue in
            if newValue != 0 {
                isFocused = false
            }
        }
        .padding(.vertical, 10)
        .onAppear {
            UserDefaults.standard.set(viewModel.nickname, forKey: "tempNickname")
        }
    }
}

#Preview {
    NicknameSettingView(currentPage: .constant(0))
        .environment(OnboardingViewModel())
}

//
//  NicknameSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

//
//  BackgroundSelectView.swift
//  Lumo
//
//  Created by 김승겸 on 1/13/26.
//

import SwiftUI

struct NicknameSettingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("닉네임을 설정해주세요.")
                .font(.Subtitle1)
                .foregroundStyle(Color.black)
                .padding(.top, 37)
            
            Text("알려주신 이름으로 알람을 보내드릴게요.")
                .font(.Body1)
                .foregroundStyle(Color(hex: "7A7F88"))
                .padding(.bottom, 57)
            
            // 닉네임 입력 필드
            VStack(spacing: 8) {
                TextField("닉네임을 입력해주세요", text: Bindable(viewModel).nickname)
                    .font(.Subtitle1)
                    .focused($isFocused) // 화면 켜지면 키보드 올라오게 설정 가능
                    .textInputAutocapitalization(.never) // 첫 글자 자동 대문자 방지
                    .disableAutocorrection(true) // 자동 수정 방지
                    .padding(.vertical, 10)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color(hex: "DDE1E8"))
            }
            
            Spacer()
        }
        .onTapGesture {
            isFocused = false
        }
        // 페이지가 바뀌면 포커스를 즉시 해제하여 화면이 되돌아가는 것 방지
        .onChange(of: currentPage) { _, newValue in
            if newValue != 0 { // 0은 현재 페이지 인덱스
                isFocused = false
            }
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    NicknameSettingView(currentPage: .constant(0))
        .environment(OnboardingViewModel())
}

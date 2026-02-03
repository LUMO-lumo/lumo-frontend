//
//  LoginView.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//

import SwiftUI

struct LoginView: View {
    // ViewModel 연결
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // 1. 로고 영역
                VStack(spacing: 10) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 98, height: 98)
                    
                    Text("LUMO")
                        .font(.Headline1)
                    
                    VStack(spacing: 3) {
                        Text("확실하게 깨워주는 진짜 알람")
                            .font(.Subtitle1)
                        
                        Text("아무리 피곤하고 지쳐도 개운하게")
                            .font(.Body1)
                            .opacity(0.4)
                    }
                    .padding(.top, 10)
                }
                .padding(.top, 79)
                
                Spacer()
                
                // 2. 입력 필드
                VStack(spacing: 10) {
                    TextField("이메일", text: $viewModel.email)
                        .padding()
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.gray300, lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("비밀번호", text: $viewModel.password)
                        .padding()
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.gray300, lineWidth: 1)
                        )
                }
                
                // 3. 체크박스 & 에러 메시지
                HStack(alignment: .center, spacing: 12) {
                    CheckboxButton(title: "자동로그인", isChecked: $viewModel.isAutoLogin)
                    CheckboxButton(title: "이메일 기억하기", isChecked: $viewModel.rememberEmail)
                    
                    Spacer()
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "F06D5B"))
                            .transition(.opacity)
                    }
                }
                .padding(.top, 12)
                
                Spacer()
                
                // 4. 하단 링크
                HStack(spacing: 12) {
                    NavigationLink(destination: Text("비밀번호 찾기")) {
                        Text("비밀번호 찾기")
                    }
                    
                    Rectangle()
                        .frame(width: 1, height: 12)
                        .foregroundStyle(Color(hex: "D9D9D9"))
                    
                    NavigationLink(destination: Text("회원가입")) {
                        Text("회원가입")
                    }
                }
                .font(.Body1)
                .foregroundStyle(.primary)
                .padding(.bottom, 12)
                
                // 5. 로그인 버튼
                Button(action: {
                    Task { await viewModel.login() }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text("로그인")
                            .font(.Subtitle3)
                            .foregroundStyle(Color.gray700)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(viewModel.isButtonEnabled ? Color.main300 : Color.gray300)
                    .foregroundStyle(Color.white)
                    .cornerRadius(8)
                }
                .disabled(!viewModel.isButtonEnabled || viewModel.isLoading)
                .padding(.bottom, 22)
            }
            .padding(.horizontal, 24)
            // 로그인 성공 시 화면 전환 로직 (예시)
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                Text("메인 화면입니다!") // 여기에 MainView()를 넣으면 됩니다.
            }
        }
    }
}

// 체크박스
struct CheckboxButton: View {
    let title: String
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) { isChecked.toggle() }
        }) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isChecked ? Color.main300 : Color.clear)
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isChecked ? Color.clear : Color.gray300, lineWidth: 1)
                    if isChecked {
                        Image("typeCheck")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 18, height: 18)
                
                Text(title)
                    .font(.pretendardSemiBold10)
                    .foregroundStyle(.black)
            }
        }
    }
}

#Preview {
    LoginView()
}

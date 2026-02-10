//
//  PWResetView.swift
//  Lumo
//
//  Created by 김승겸 on 2/7/26.
//

import SwiftData
import SwiftUI

struct PWResetView: View {
    
    @StateObject private var viewModel = PasswordResetViewModel()
    
    @Environment(\.dismiss) private var dismiss
    @Binding var isTabBarHidden: Bool
    
    var body: some View {
        VStack {
            // 1. 상단 네비게이션 (뒤로가기/닫기)
            HStack {
                Button(action: {
                    handleBackButton()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.black)
                }
                Spacer()
            }
            .padding(.bottom, 20)
            
            // 2. 단계별 화면 교체 (Switch-Case)
            switch viewModel.step {
            case .inputEmail:
                inputEmailView
                
            case .verification:
                verificationView
                
            case .resetPassword:
                resetPasswordView
            }
        }
        .padding(.horizontal, 24)
        .navigationBarHidden(true)
        .onAppear {
            isTabBarHidden = true
        }
        // 공통 알림창
        .alert("알림", isPresented: $viewModel.showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "잠시 후 다시 시도해주세요.")
        }
        // 로딩 처리
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    // 뒤로가기 버튼 로직 처리
    private func handleBackButton() {
        switch viewModel.step {
        case .inputEmail:
            dismiss() // 첫 화면에서는 창 닫기
        case .verification:
            withAnimation { viewModel.step = .inputEmail } // 이전 단계로
        case .resetPassword:
            withAnimation { viewModel.step = .verification } // 이전 단계로
        }
    }
    
    // MARK: - 1단계: 이메일 입력 화면
    
    var inputEmailView: some View {
        VStack(alignment: .leading) {
            Text("비밀번호 찾기")
                .lineSpacing(14)
                .font(.Headline2)
                .padding(.bottom, 4)
            
            Text("비밀번호를 재설정하실 이메일을 입력해주세요")
                .font(.Body1)
                .padding(.bottom, 36)
            
            // 이메일 입력 필드
            ZStack(alignment: .leading) {
                if viewModel.email.isEmpty {
                    Text("이메일")
                        .font(.Subtitle3)
                        .foregroundStyle(Color.gray700)
                        .padding(.horizontal, 18)
                        .padding(.vertical)
                }
                
                TextField("", text: $viewModel.email)
                    .font(.Subtitle3)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray300)
            )
            .cornerRadius(8)
            
            // 에러 메시지
            if let error = viewModel.emailError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "F06D5B"))
                    .padding(.top, 14)
            }
            
            Spacer()
            
            Button(action: {
                _Concurrency.Task{ // ✅ 변경된 함수명 적용
                    await viewModel.userRequestAuthCode()
                }
            }) {
                Text("다음")
                    .font(.Subtitle3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(
                        viewModel.email.isEmpty ? Color.gray700 : Color.white
                    )
                    .background(
                        viewModel.email.isEmpty ? Color.gray300 : Color.main300
                    )
                    .cornerRadius(8)
            }
            .disabled(viewModel.email.isEmpty)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 2단계: 인증번호 입력 화면
    
    var verificationView: some View {
        VStack(alignment: .leading) {
            Text("이메일 인증")
                .font(.Headline2)
                .padding(.bottom, 4)
            
            Text("메일로 발송된 인증번호를 입력해주세요")
                .font(.Body1)
                .padding(.bottom, 36)
            
            ZStack(alignment: .leading) {
                if viewModel.authCode.isEmpty {
                    Text("인증번호")
                        .font(.Subtitle3)
                        .foregroundStyle(Color.gray700)
                        .padding(.horizontal, 18)
                        .padding(.vertical)
                }
                
                TextField("", text: $viewModel.authCode)
                    .font(.Subtitle3)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical)
                    .keyboardType(.default)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray300)
            )
            .cornerRadius(8)
            
            HStack {
                Spacer()
                Button(action: {
                    _Concurrency.Task {
                        // ✅ 변경된 함수명 적용 (재전송)
                        await viewModel.userRequestAuthCode()
                    }
                }) {
                    Text("인증번호 재전송")
                        .font(.pretendardSemiBold10)
                        .foregroundStyle(Color.black)
                        .underline()
                }
                Spacer()
            }
            .padding(.top, 14)
            
            Spacer()
            
            Button(action: {
                _Concurrency.Task {
                    // ✅ 변경된 함수명 적용
                    await viewModel.userVerifyAuthCode()
                }
            }) {
                Text("확인")
                    .font(.Subtitle3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(
                        viewModel.authCode.isEmpty ? Color.gray700 : Color.white
                    )
                    .background(
                        viewModel.authCode.isEmpty ? Color.gray300 : Color.main300
                    )
                    .cornerRadius(8)
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 3단계: 비밀번호 재설정 화면
    
    var resetPasswordView: some View {
        VStack(alignment: .leading) {
            Text("비밀번호 재설정")
                .font(.Headline2)
                .padding(.bottom, 4)
            
            Text("변경하실 비밀번호를 입력해주세요")
                .font(.Body1)
                .padding(.bottom, 36)
            
            // 새 비밀번호
            ZStack(alignment: .leading) {
                if viewModel.newPassword.isEmpty {
                    Text("새 비밀번호")
                        .font(.Subtitle3)
                        .foregroundStyle(Color.gray700)
                        .padding(.horizontal, 18)
                        .padding(.vertical)
                }
                
                SecureField("", text: $viewModel.newPassword)
                    .font(.Subtitle3)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray300)
            )
            .cornerRadius(8)
            .padding(.bottom, 12)
            
            // 비밀번호 확인
            ZStack(alignment: .leading) {
                if viewModel.confirmPassword.isEmpty {
                    Text("비밀번호 확인")
                        .font(.Subtitle3)
                        .foregroundStyle(Color.gray700)
                        .padding(.horizontal, 18)
                        .padding(.vertical)
                }
                
                SecureField("", text: $viewModel.confirmPassword)
                    .font(.Subtitle3)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray300)
            )
            .cornerRadius(8)
            
            Spacer()
            
            Button(action: {
                _Concurrency.Task {
                    // ✅ 변경된 함수명 적용
                    let isSuccess = await viewModel.userUpdatePassword()
                    if isSuccess {
                        dismiss() // 성공 시 창 닫고 로그인 화면으로
                    }
                }
            }) {
                Text("비밀번호 변경")
                    .font(.Subtitle3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(
                        (viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty)
                            ? Color.gray300
                            : Color.main300
                    )
                    .cornerRadius(8)
            }
            .disabled(
                viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty
            )
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Previews

#Preview("비밀번호 찾기 (전체)") {
    PWResetView(isTabBarHidden: .constant(true))
}

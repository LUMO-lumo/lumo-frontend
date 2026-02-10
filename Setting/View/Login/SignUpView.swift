//
//  SignUpView.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//

import SwiftData
import SwiftUI

struct SignUpView: View {
    
    @StateObject var viewModel: SignUpViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var isTabBarHidden: Bool
    
    // 프로필 설정 화면으로 이동하기 위한 상태 변수
    @State private var navigateToProfile = false
    
    init(
        viewModel: SignUpViewModel = SignUpViewModel(),
        isTabBarHidden: Binding<Bool>
    ) {
        // 입력받은 viewModel로 StateObject를 초기화
        _viewModel = StateObject(wrappedValue: viewModel)
        _isTabBarHidden = isTabBarHidden
    }
    
    var body: some View {
        VStack {
            if viewModel.step != .success {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.black)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            
            // 단계별 화면 전환
            switch viewModel.step {
            case .inputInfo:
                inputInfoView
            case .verification:
                verificationView
            case .success:
                successView
            }
        }
        .padding(.horizontal, 24)
        .navigationBarHidden(true) // 기본 네비게이션 바 숨김 (커스텀 사용)
        .navigationDestination(isPresented: $navigateToProfile) {
            ProfileSettingView(isTabBarHidden: $isTabBarHidden)
        }
    }
    
    // MARK: - 1단계: 정보 입력 화면
    
    var inputInfoView: some View {
        VStack(alignment: .leading) {
            Text("회원가입")
                .font(.Headline2)
                .padding(.bottom, 4)
            
            Text("가입하실 이메일과 비밀번호를 입력해주세요")
                .font(.Body1)
                .padding(.bottom, 36)
            
            // 입력 필드
            VStack(spacing: 12) {
                TextField("이메일", text: $viewModel.email)
                    .padding()
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.gray300)
                    )
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                SecureField("비밀번호", text: $viewModel.password)
                    .padding()
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.gray300)
                    )
            }
            
            // 체크박스
            HStack(spacing: 12) {
                CheckboxButton(
                    title: "자동로그인",
                    isChecked: $viewModel.isAutoLogin
                )
                CheckboxButton(
                    title: "이메일 기억하기",
                    isChecked: $viewModel.rememberEmail
                )
                
                Spacer()
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.pretendardSemiBold10)
                        .foregroundStyle(Color(hex: "F06D5B"))
                }
            }
            .padding(.top, 14)
            
            Button(action: {
                Task {
                    await viewModel.userRequestVerificationCode()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    
                    Text("다음")
                        .font(.Subtitle3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.isInputStepValid ? Color.main300 : Color.gray300)
                .foregroundStyle(Color.gray700)
                .cornerRadius(8)
            }
            .disabled(!viewModel.isInputStepValid || viewModel.isLoading)
            .padding(.top, 18)
            
            Spacer()
        }
    }
    
    // MARK: - 2단계: 이메일 인증 화면
    
    var verificationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("이메일 인증")
                .font(.Headline2)
                .padding(.bottom, 4)
            
            Text("메일로 발송된 인증번호를 입력해주세요")
                .font(.Body1)
                .padding(.bottom, 36)
            
            TextField("인증번호", text: $viewModel.verificationCode)
                .padding()
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray300)
                )
                .keyboardType(.default)
            
            // 인증번호 재전송 버튼
            HStack {
                Spacer()
                Button("인증번호 재전송") {
                    Task {
                        await viewModel.userRequestVerificationCode()
                    }
                }
                .font(.pretendardSemiBold10)
                .foregroundStyle(Color.black)
                .underline()
                
                Spacer()
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(Color(hex: "F06D5B"))
                    .font(.pretendardSemiBold10)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Button(action: {
                Task {
                    // 검증 성공 시 회원가입 요청 함수를 부를 때 context 전달
                    await viewModel.userVerifyCodeAndSignUp(modelContext: modelContext)
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Text("확인")
                        .font(.Subtitle3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(viewModel.isVerifyStepValid ? Color.main300 : Color.gray300)
                .foregroundStyle(Color.gray700)
                .cornerRadius(8)
            }
            .disabled(!viewModel.isVerifyStepValid || viewModel.isLoading)
            .padding(.bottom, 20)
            
            Spacer()
        }
    }
    
    // MARK: - 3단계: 가입 완료 화면
    
    var successView: some View {
        VStack {
            Spacer()
            
            VStack {
                // 체크 아이콘 (에셋 이미지)
                Image("SignUpCompleted")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 102, height: 63)
                    .padding(.bottom, 36)
                
                Text("가입을 완료했어요")
                    .font(.Headline1)
            }
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                // 3초 뒤 프로필 설정 화면으로 이동
                withAnimation {
                    navigateToProfile = true
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("가입 완료 화면") {
    let successVM = SignUpViewModel(step: .success)
    
    return SignUpView(
        viewModel: successVM,
        isTabBarHidden: .constant(false)
    )
    .modelContainer(for: UserModel.self, inMemory: true)
}

#Preview("입력 화면 (기본)") {
    SignUpView(isTabBarHidden: .constant(true))
        .modelContainer(for: UserModel.self, inMemory: true)
}

#Preview("이메일 인증 화면") {
    let verificationVM = SignUpViewModel(step: .verification)
    
    return SignUpView(
        viewModel: verificationVM,
        isTabBarHidden: .constant(true)
    )
    .modelContainer(for: UserModel.self, inMemory: true)
}

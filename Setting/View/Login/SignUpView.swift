//
//  SignUpView.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//

import SwiftUI
import SwiftData

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss // 성공 후 나가기 위해 필요
    @Environment(\.modelContext) private var modelContext // ⭐️ SwiftData 컨텍스트 가져오기
    @Binding var isTabBarHidden: Bool
    
    var body: some View {
        VStack {
            // 상단 네비게이션 바 (뒤로가기 버튼 등)
            // 성공 화면이 아닐 때만 표시
            if viewModel.step != .success {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding()
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
        .navigationBarHidden(true) // 기본 네비게이션 바 숨김 (커스텀 사용)
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
                    .background(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.gray.opacity(0.3)))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                SecureField("비밀번호", text: $viewModel.password)
                    .padding()
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.gray.opacity(0.3)))
            }
            
            // 체크박스 (LoginView에 있던 CheckboxButton 재사용)
            HStack(spacing: 12) {
                CheckboxButton(title: "자동로그인", isChecked: $viewModel.isAutoLogin)
                CheckboxButton(title: "이메일 기억하기", isChecked: $viewModel.rememberEmail)
                Spacer()
                
                if let error = viewModel.errorMessage {
                    Text(error) // "사용자 이메일을 다시 확인해주세요" 등
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 14)
            
            Button(action: {
                Task { await viewModel.userRequestVerificationCode() }
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
                .foregroundColor(.gray700)
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
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("메일로 발송된 인증번호를 입력해주세요")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            TextField("인증번호", text: $viewModel.verificationCode)
                .padding()
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.gray.opacity(0.3)))
                .keyboardType(.numberPad)
            
            // 인증번호 재전송 버튼 (기능 구현은 선택)
            HStack {
                Spacer()
                Button("인증번호 재전송") {
                    Task { await viewModel.userRequestVerificationCode() }
                }
                .font(.caption)
                .foregroundColor(.gray)
                .underline()
                Spacer()
            }
            
            Spacer()
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Button(action: {
                Task {
                    // 검증 성공 시 회원가입 요청 함수를 부를 때 context 전달
                    await viewModel.userVerifyCodeAndSignUp(modelContext: modelContext)
                }
            }) {
                HStack {
                    if viewModel.isLoading { ProgressView() }
                    Text("확인")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.isVerifyStepValid ? Color.orange : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!viewModel.isVerifyStepValid || viewModel.isLoading)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 3단계: 가입 완료 화면
    var successView: some View {
        VStack {
            Spacer()
            
            Image(systemName: "checkmark") // 체크 아이콘 (에셋 이미지로 교체 가능)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)
                .padding(.bottom, 20)
            
            Text("가입을 완료했어요")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // 완료 버튼을 누르면 로그인 화면으로 돌아가거나 메인으로 이동
            Button(action: {
                dismiss() // 로그인 화면으로 복귀
            }) {
                Text("로그인하러 가기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    SignUpView(isTabBarHidden: .constant(false))
}

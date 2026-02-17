//
//  PasswordResetViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/7/26.
//

import Combine
import Foundation
import SwiftUI

import Moya

// 단계 정의
enum ResetStep {
    case inputEmail        // 1단계: 이메일 입력
    case verification    // 2단계: 인증번호 입력
    case resetPassword    // 3단계: 비밀번호 재설정
}

class PasswordResetViewModel: ObservableObject {
    
    // MARK: - Properties
    
    // ✅ 화면 상태 관리 (이 변수가 바뀌면 View의 switch문이 반응함)
    @Published var step: ResetStep = .inputEmail
    
    // 입력 데이터
    @Published var email: String = ""
    @Published var authCode: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    // UI 상태
    @Published var isLoading: Bool = false
    @Published var emailError: String? = nil        // 이메일 입력 화면 에러
    @Published var errorMessage: String? = nil        // 공통 에러 (Alert용)
    @Published var isCodeVerified: Bool = false
    @Published var showAlert: Bool = false            // Alert 트리거
    
    // 유효성 검사
    var isEmailValid: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
    
    private let provider: MoyaProvider<UserTarget> = MoyaProvider()
    
    // MARK: - Action Functions
    
    /// 1단계: 이메일 존재 확인 후 인증번호 전송
    @MainActor
    func userRequestAuthCode() async {
        guard isEmailValid else {
            emailError = "올바른 이메일 형식이 아닙니다."
            return
        }
        
        isLoading = true
        emailError = nil
        errorMessage = nil
        
        // 1. 이메일 존재 여부 확인 (Find Email)
        let findResult = await provider.request(.findEmailForReset(email: email))
        
        switch findResult {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 이메일 존재 확인 완료")
                
                // 2. 존재한다면 인증번호 발송 요청 (Request Code)
                await requestVerificationCodeInternal()
                
            } catch {
                if let errorData = try? response.map(APIResponse.self) {
                    emailError = errorData.message ?? "가입되지 않은 이메일입니다."
                } else {
                    emailError = "등록되지 않은 이메일입니다."
                }
                isLoading = false
            }
            
        case .failure(let error):
            print("❌ 이메일 찾기 에러: \(error)")
            emailError = "네트워크 연결을 확인해주세요."
            isLoading = false
        }
    }
    
    /// 내부 함수: 실제 인증번호 발송
    @MainActor
    private func requestVerificationCodeInternal() async {
        let result = await provider.request(.requestVerificationCode(email: email))
        
        switch result {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 인증 코드 발송 성공")
                
                // ✅ Step 변경으로 화면 전환
                withAnimation {
                    self.step = .verification
                }
                
            } catch {
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "인증 코드 발송 실패"
                    showAlert = true
                }
            }
            
        case .failure(let error):
            print("❌ 인증코드 발송 에러: \(error)")
            errorMessage = "네트워크 오류가 발생했습니다."
            showAlert = true
        }
        
        isLoading = false
    }
    
    /// 2단계: 인증 코드 검증
    @MainActor
    func userVerifyAuthCode() async {
        guard !authCode.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let result = await provider.request(
            .verifyCode(email: email, code: authCode)
        )
        
        switch result {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 인증 번호 검증 성공")
                isCodeVerified = true
                
                // ✅ Step 변경으로 화면 전환
                withAnimation {
                    self.step = .resetPassword
                }
                
            } catch {
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "인증 번호가 일치하지 않습니다."
                } else {
                    errorMessage = "인증에 실패했습니다."
                }
                showAlert = true
            }
            
        case .failure:
            errorMessage = "네트워크 오류"
            showAlert = true
        }
        
        isLoading = false
    }
    
    /// 3단계: 비밀번호 변경 요청
    @MainActor
    func userUpdatePassword() async -> Bool {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            return false
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "비밀번호가 일치하지 않습니다."
            showAlert = true
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        let requestBody = ChangePasswordRequest(
            email: email,
            password: newPassword
        )
        
        let result = await provider.request(
            .changePassword(request: requestBody)
        )
        
        var isSuccess = false
        
        switch result {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("🎉 비밀번호 변경 성공")
                isSuccess = true
                
            } catch {
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "비밀번호 변경 실패"
                } else {
                    errorMessage = "비밀번호 변경 중 오류가 발생했습니다."
                }
                showAlert = true
            }
            
        case .failure:
            errorMessage = "서버 통신 오류"
            showAlert = true
        }
        
        isLoading = false
        return isSuccess
    }
}

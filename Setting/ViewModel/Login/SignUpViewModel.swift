//
//  SignUpViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//

import Combine
import Foundation
import SwiftData

/// 회원가입 화면의 단계를 정의하는 열거형
enum SignUpStep {
    case inputInfo      // 이메일/비번 입력
    case verification   // 인증번호 입력
    case success        // 가입 완료
}

class SignUpViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var nickname: String = "LumoUser"
    @Published var verificationCode: String = ""
    
    @Published var isAutoLogin: Bool = false
    @Published var rememberEmail: Bool = false
    
    @Published var step: SignUpStep = .inputInfo
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let baseURL = AppConfig.baseURL
    
    var isInputStepValid: Bool {
        return !email.isEmpty && !password.isEmpty
    }
    
    var isVerifyStepValid: Bool {
        return !verificationCode.isEmpty
    }
    
    // MARK: - Initialization
    
    init(step: SignUpStep = .inputInfo) {
        self.step = step
    }
    
    // MARK: - Action Functions
    
    /// 0단계: 이메일 중복 체크 (GET)
    @MainActor
    func userCheckEmailDuplicate() async -> Bool {
        guard var urlComponents = URLComponents(string: "\(baseURL)/api/member/email-duplicate")
        else {
            return false
        }
        
        urlComponents.queryItems = [
            URLQueryItem(
                name: "email",
                value: email
            )
        ]
        
        guard let url = urlComponents.url
        else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("이메일 중복 통과 (사용 가능)")
                return true
            } else {
                let decoded = try JSONDecoder().decode(
                    APIResponse.self,
                    from: data
                )
                self.errorMessage = decoded.message ?? "이미 가입된 이메일입니다."
                return false
            }
        } catch {
            self.errorMessage = "서버 통신 오류"
            return false
        }
    }
    
    /// 1단계: 인증 코드 요청 (POST)
    @MainActor
    func userRequestVerificationCode() async {
        guard isInputStepValid
        else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 이메일 중복 체크 실행
        let isAvailable = await userCheckEmailDuplicate()
        
        guard isAvailable
        else {
            isLoading = false
            return
        }
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/api/member/request-code")
        else {
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(
                name: "email",
                value: email
            )
        ]
        
        guard let url = urlComponents.url
        else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("인증 코드 발송 성공")
                self.step = .verification
            } else {
                let decoded = try JSONDecoder().decode(
                    APIResponse.self,
                    from: data
                )
                self.errorMessage = decoded.message ?? "인증 코드 발송에 실패했습니다."
            }
        } catch {
            self.errorMessage = "네트워크 오류가 발생했습니다."
        }
        
        isLoading = false
    }
    
    /// 2단계: 인증 코드 검증 (POST)
    @MainActor
    func userVerifyCodeAndSignUp(modelContext: ModelContext) async {
        guard isVerifyStepValid
        else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/api/member/verify-code")
        else {
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(
                name: "email",
                value: email
            ),
            URLQueryItem(
                name: "code",
                value: verificationCode
            )
        ]
        
        guard let url = urlComponents.url
        else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("인증 번호 검증 성공")
                await userRequestSignUp(modelContext: modelContext)
            } else {
                let decoded = try JSONDecoder().decode(
                    APIResponse.self,
                    from: data
                )
                self.errorMessage = decoded.message ?? "인증 번호가 올바르지 않습니다."
                isLoading = false
            }
        } catch {
            self.errorMessage = "네트워크 오류가 발생했습니다."
            isLoading = false
        }
    }
    
    /// 3단계: 최종 회원가입 요청 (POST)
    @MainActor
    func userRequestSignUp(modelContext: ModelContext) async {
        guard let url = URL(string: "\(baseURL)/api/member/signin")
        else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        let bodyData = SignUpRequest(
            email: email,
            password: password,
            username: self.nickname
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(bodyData)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                
                let decoded = try JSONDecoder().decode(
                    APIResponse.self,
                    from: data
                )
                
                if decoded.success {
                    print("회원가입 최종 성공")
                    
                    if let token = decoded.result?.accessToken {
                        KeychainManager.shared.save(
                            token: token,
                            for: "accessToken"
                        )
                    }
                    
                    let newUser = UserModel(nickname: self.nickname)
                    modelContext.insert(newUser)
                    
                    self.step = .success
                } else {
                    self.errorMessage = decoded.message ?? "회원가입 실패"
                }
            } else {
                let decoded = try JSONDecoder().decode(
                    APIResponse.self,
                    from: data
                )
                self.errorMessage = decoded.message ?? "회원가입 요청 실패"
            }
        } catch {
            self.errorMessage = "서버 통신 오류"
        }
        
        isLoading = false
    }
}

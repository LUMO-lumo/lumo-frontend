//
//    SignUpViewModel.swift
//    Lumo
//
//    Created by 김승겸 on 2/2/26.
//

import Combine
import Foundation
import SwiftData

import Moya

/// 회원가입 화면의 단계를 정의하는 열거형
enum SignUpStep {
    case inputInfo
    case verification
    case success
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
    
    private let baseURL: String = AppConfig.baseURL
    
    var isInputStepValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var isVerifyStepValid: Bool {
        !verificationCode.isEmpty
    }
    
    private let provider: MoyaProvider<UserTarget> = MoyaProvider()
    
    // MARK: - Initialization
    
    init(step: SignUpStep = .inputInfo) {
        self.step = step
    }
    
    // MARK: - Action Functions
    
    /// 0단계: 이메일 중복 체크 (GET)
    @MainActor
    func userCheckEmailDuplicate() async -> Bool {
        // Moya 요청
        let result = await provider.request(.checkEmailDuplicate(email: email))
        
        switch result {
        case .success(let response):
            do {
                // 상태 코드 200~299 확인
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 이메일 중복 아님 (사용 가능)")
                return true
            } catch {
                // 400 등 실패 시
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "이미 가입된 이메일입니다."
                } else {
                    errorMessage = "서버 오류가 발생했습니다."
                }
                return false
            }
            
        case .failure(let error):
            print("❌ Moya 에러: \(error)")
            errorMessage = "네트워크 연결을 확인해주세요."
            return false
        }
    }
    
    /// 1단계: 인증 코드 요청 (POST)
    @MainActor
    func userRequestVerificationCode() async {
        guard isInputStepValid else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 이메일 중복 체크 실행
        let isAvailable = await userCheckEmailDuplicate()
        
        guard isAvailable else {
            isLoading = false
            return
        }
        
        // Moya 요청
        let result = await provider.request(.requestVerificationCode(email: email))
        
        switch result {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 인증 코드 발송 성공")
                step = .verification
            } catch {
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "인증 코드 발송 실패"
                }
            }
            
        case .failure(let error):
            print("❌ 에러: \(error)")
            errorMessage = "네트워크 오류"
        }
        
        isLoading = false
    }
    
    /// 2단계: 인증 코드 검증 (POST)
    @MainActor
    func userVerifyCodeAndSignUp(modelContext: ModelContext) async {
        guard isVerifyStepValid else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Moya 요청
        let result = await provider.request(.verifyCode(email: email, code: verificationCode))
        
        switch result {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 인증 번호 검증 성공")
                await userRequestSignUp(modelContext: modelContext)
            } catch {
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "인증 번호가 다릅니다."
                }
                isLoading = false
            }
            
        case .failure:
            errorMessage = "네트워크 오류"
            isLoading = false
        }
    }
    
    /// 3단계: 최종 회원가입 요청 (POST)
    @MainActor
    func userRequestSignUp(modelContext: ModelContext) async {
        // Request 객체 생성
        let requestBody = SignUpRequest(
            email: email,
            password: password,
            username: nickname
        )
        
        // Moya 요청
        let result = await provider.request(.signUp(request: requestBody))
        
        switch result {
        case .success(let response):
            do {
                // 성공 상태 코드 체크
                _ = try response.filterSuccessfulStatusCodes()
                
                // 디코딩
                let decoded = try response.map(APIResponse.self)
                
                if decoded.success {
                    print("🎉 회원가입 최종 성공")
                    
                    if let token = decoded.result?.accessToken {
                        let userInfo = UserInfo(accessToken: token, refreshToken: nil)
                        _ = KeychainManager.standard.saveSession(userInfo, for: "userSession")
                    }
                    
                    let newUser = UserModel(nickname: nickname)
                    modelContext.insert(newUser)
                    
                    step = .success
                } else {
                    errorMessage = decoded.message ?? "회원가입 실패"
                }
            } catch {
                // 상태 코드가 200번대가 아닐 때
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "요청 처리 중 오류가 발생했습니다."
                }
            }
            
        case .failure:
            errorMessage = "서버 통신 오류"
        }
        
        isLoading = false
    }
}

extension MoyaProvider {
    // 컴파일러의 엄격한 Sendable 검사를 우회하기 위한 래퍼
    struct UncheckedSendable<T>: @unchecked Sendable {
        let value: T
    }
    
    // 원본 Response를 그대로 반환하는 async 래퍼
    func request(_ target: Target) async -> Result<Response, MoyaError> {
        // continuation의 반환 타입을 UncheckedSendable<Result<...>>로 맞춤
        let safeResult = await withCheckedContinuation { (continuation: CheckedContinuation<UncheckedSendable<Result<Response, MoyaError>>, Never>) in
            self.request(target) { result in
                continuation.resume(returning: UncheckedSendable(value: result))
            }
        }
        
        return safeResult.value
    }
}

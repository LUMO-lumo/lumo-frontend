//
//  SignUpViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
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

@MainActor
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
    
    // APIManager나 MoyaProvider 생성 방식은 프로젝트 상황에 맞게 유지
    private let provider = APIManager.shared.createProvider(for: UserTarget.self)
    
    // MARK: - Initialization
    
    init(step: SignUpStep = .inputInfo) {
        self.step = step
    }
    
    // MARK: - Action Functions
    
    /// 0단계: 이메일 중복 체크 (GET)
    func userCheckEmailDuplicate() async -> Bool {
        let result = await provider.request(.checkEmailDuplicate(email: email))
        
        switch result {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 이메일 중복 아님 (사용 가능)")
                return true
            } catch {
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
    func userRequestVerificationCode() async {
        guard isInputStepValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 이메일 중복 체크 실행
        let isAvailable = await userCheckEmailDuplicate()
        
        guard isAvailable else {
            isLoading = false
            return
        }
        
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
    func userVerifyCodeAndSignUp(modelContext: ModelContext) async {
        guard isVerifyStepValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let result = await provider.request(.verifyCode(email: email, code: verificationCode))
        
        switch result {
        case .success(let response):
            do {
                _ = try response.filterSuccessfulStatusCodes()
                print("✅ 인증 번호 검증 성공 -> 회원가입 요청 진행")
                
                // ⚠️ 중요: 여기서 isLoading을 끄지 않고 회원가입 요청으로 이어갑니다.
                // 회원가입 함수(userRequestSignUp)가 끝나면 거기서 isLoading이 false가 됩니다.
                await userRequestSignUp(modelContext: modelContext)
                
            } catch {
                // 검증 실패 시 에러 메시지 파싱
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "인증 번호가 다릅니다."
                }
                isLoading = false // 여기서만 끄기
            }
            
        case .failure:
            errorMessage = "네트워크 오류"
            isLoading = false
        }
    }
    
    /// 3단계: 최종 회원가입 요청 (POST)
    func userRequestSignUp(modelContext: ModelContext) async {
        
        // 함수가 종료되면 무조건 로딩을 끄도록 보장
        defer { isLoading = false }
        
        let storedNickname = UserDefaults.standard.string(forKey: "tempNickname") ?? self.nickname
        print("🚀 회원가입 요청 시작 - 닉네임: \(storedNickname)")
        
        let requestBody = SignUpRequest(
            email: email,
            password: password,
            username: storedNickname
        )
        
        let result = await provider.request(.signUp(request: requestBody))
        
        switch result {
        case .success(let response):
            // 🔍 디버깅: 서버에서 온 원본 데이터를 문자열로 출력해봅니다.
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("📩 서버 응답(Raw): \(jsonString)")
            }
            
            do {
                _ = try response.filterSuccessfulStatusCodes()
                
                // ⚠️ 여기서 매핑이 실패하면 바로 catch로 넘어갑니다.
                let decoded = try response.map(APIResponse.self)
                
                if decoded.success {
                    print("🎉 회원가입 로직 성공! 토큰 저장을 시도합니다.")
                    
                    // 1. 토큰 저장 (수정됨: try-catch 추가)
                    if let resultData = decoded.result, let token = resultData.accessToken {
                        let userInfo = UserInfo(accessToken: token, refreshToken: nil)
                        
                        do {
                            // saveSession이 throws를 하므로 try 사용
                            try KeychainManager.standard.saveSession(userInfo, for: "userSession")
                            print("🔑 토큰 키체인 저장 완료")
                        } catch {
                            print("❌ 키체인 저장 실패: \(error)")
                            // 회원가입은 성공했지만 자동 로그인이 안 될 수 있음을 인지해야 함
                        }
                    } else {
                        print("⚠️ 경고: 성공 응답이지만 토큰이 없습니다.")
                    }
                    
                    // 2. SwiftData 저장
                    let newUser = UserModel(nickname: storedNickname)
                    modelContext.insert(newUser)
                    print("💾 SwiftData 유저 저장 완료")
                    
                    self.step = .success
                    print("👉 단계 변경 완료: .success")
                    
                } else {
                    // success가 false인 경우
                    print("❌ 회원가입 실패(서버 메시지): \(decoded.message ?? "없음")")
                    errorMessage = decoded.message ?? "회원가입 실패"
                }
                
            } catch {
                print("❌ 데이터 매핑 또는 상태 코드 에러: \(error)")
                
                // 매핑 실패 원인을 알기 위해 디코딩 시도 (선택 사항)
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message ?? "요청 처리 중 오류가 발생했습니다."
                } else {
                    errorMessage = "서버 응답을 처리할 수 없습니다."
                }
            }
            
        case .failure(let error):
            print("❌ 네트워크 통신 에러: \(error)")
            errorMessage = "서버 통신 오류"
        }
    }
}

// 아래 Extension은 그대로 유지 (비동기 처리에 유용함)
extension MoyaProvider {
    // 컴파일러의 엄격한 Sendable 검사를 우회하기 위한 래퍼
    struct UncheckedSendable<T>: @unchecked Sendable {
        let value: T
    }
    
    // 원본 Response를 그대로 반환하는 async 래퍼
    func request(_ target: Target) async -> Result<Response, MoyaError> {
        let safeResult = await withCheckedContinuation { (continuation: CheckedContinuation<UncheckedSendable<Result<Response, MoyaError>>, Never>) in
            self.request(target) { result in
                continuation.resume(returning: UncheckedSendable(value: result))
            }
        }
        return safeResult.value
    }
}

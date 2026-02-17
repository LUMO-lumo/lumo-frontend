//
//  LoginViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//

import Combine
import Foundation
import SwiftData
import Moya

class LoginViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAutoLogin: Bool = false
    @Published var rememberEmail: Bool = false
    
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var isLoggedIn: Bool = false
    
    private let baseURL: String = AppConfig.baseURL
    
    var isButtonEnabled: Bool {
        return !email.isEmpty && !password.isEmpty
    }
    
    private let provider: MoyaProvider<UserTarget> = MoyaProvider()
    
    init() {}
    
    // MARK: - Action Functions
    
    /// 로그인 요청 (POST)
    @MainActor
    func userLogin(modelContext: ModelContext) async {
        guard isButtonEnabled else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let requestBody = LoginRequest(
            email: email,
            password: password
        )
        
        // Moya 요청
        let result = await provider.request(.login(request: requestBody))
        
        switch result {
        case .success(let response):
            do {
                // 성공(200~299)인지 확인
                _ = try response.filterSuccessfulStatusCodes()
                
                // APIResponse 타입을 디코딩 (제네릭 타입 확인 필요, 여기서는 APIResponse<LoginResult>라고 가정하거나 기존 구조체 사용)
                // 만약 APIResponse가 제네릭이 아니라면 기존 코드 유지
                let decoded = try response.map(APIResponse.self)
                
                if decoded.success {
                    print("✅ 로그인 API 호출 성공")
                    
                    if let resultData = decoded.result {
                        
                        // 1. 토큰 저장 (수정됨: try-catch 추가)
                        if let token = resultData.accessToken {
                            
                            print("\n🔥🔥🔥 [DEBUG] SWAGGER용 토큰: \(token)\n")
                            
                            let userInfo = UserInfo(
                                accessToken: token,
                                refreshToken: nil // 필요하다면 리프레시 토큰도 여기에 추가
                            )
                            
                            do {
                                try KeychainManager.standard.saveSession(
                                    userInfo,
                                    for: "userSession"
                                )
                                print("💾 키체인에 세션 저장 완료")
                            } catch {
                                print("❌ 키체인 저장 실패: \(error)")
                                // 심각한 에러라면 여기서 isLoggedIn = false로 막을 수도 있음
                            }
                        }
                        
                        // 🔍 [디버깅] 닉네임 로직
                        let serverNickname = resultData.username
                        let tempNickname = UserDefaults.standard.string(forKey: "tempNickname")
                        
                        print("🌍 서버 닉네임: \(serverNickname ?? "없음")")
                        print("📱 임시 닉네임: \(tempNickname ?? "없음")")
                        
                        // ⭐️ 우선순위: tempNickname > serverNickname > "LumoUser"
                        let realNickname = tempNickname ?? serverNickname ?? "LumoUser"
                        
                        print("✅ 최종 결정된 닉네임: \(realNickname)")
                        
                        // 2. 유저 데이터 생성 또는 업데이트 (SwiftData)
                        let descriptor = FetchDescriptor<UserModel>()
                        let existingUsers = try? modelContext.fetch(descriptor)
                        
                        if let existingUser = existingUsers?.first {
                            existingUser.nickname = realNickname
                            print("♻️ 기존 유저 닉네임 업데이트 완료")
                        } else {
                            let newUser = UserModel(nickname: realNickname)
                            modelContext.insert(newUser)
                            print("✨ 새 유저 생성 완료")
                        }
                        
                        // 3. SwiftData 저장
                        try? modelContext.save()
                        
                        // [중요] 사용한 임시 닉네임 삭제
                        UserDefaults.standard.removeObject(forKey: "tempNickname")
                    }
                    
                    // 모든 처리가 끝난 후 로그인 상태 변경
                    isLoggedIn = true
                    
                } else {
                    errorMessage = decoded.message ?? "로그인 실패"
                }
            } catch {
                // 실패(400~500) 처리 혹은 디코딩 에러
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message
                } else {
                    errorMessage = "서버 오류 또는 데이터 처리 중 문제가 발생했습니다."
                }
                print("❌ 로그인 처리 중 에러: \(error)")
            }
            
        case .failure(let error):
            // 🔍 여기서 서버가 보낸 진짜 에러 메시지를 확인합니다.
            if let response = error.response {
                let errorBody = String(data: response.data, encoding: .utf8)
                print("❌ [HTTP \(response.statusCode)] 서버 에러 메시지: \(errorBody ?? "없음")")
                errorMessage = "로그인에 실패했습니다. (코드: \(response.statusCode))"
            } else {
                print("❌ 네트워크 연결 실패: \(error.localizedDescription)")
                errorMessage = "네트워크 연결을 확인해주세요."
            }
        }
        
        isLoading = false
    }
}

/// 로그인 요청 바디
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

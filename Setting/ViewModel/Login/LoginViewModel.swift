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
                
                let decoded = try response.map(APIResponse.self)
                
                if decoded.success {
                    print("✅ 로그인 성공")
                    
                    if let resultData = decoded.result {
                        
                        // 1. 토큰 저장 (원본 로직 유지)
                        if let token = decoded.result?.accessToken {
                            let userInfo = UserInfo(
                                accessToken: token,
                                refreshToken: nil
                            )
                            _ = KeychainManager.standard.saveSession(
                                userInfo,
                                for: "userSession"
                            )
                        }
                        
                        // 🔍 [디버깅] 현재 값 확인하기 (로그로 확인해보세요)
                        let serverNickname = resultData.username
                        let tempNickname = UserDefaults.standard.string(forKey: "tempNickname")
                        
                        print("🌍 서버 닉네임: \(serverNickname ?? "없음")")
                        print("📱 임시 닉네임: \(tempNickname ?? "없음")")
                        
                        // ⭐️ [수정 핵심] 우선순위 변경
                        // 1순위: 방금 입력한 임시 닉네임 (tempNickname)
                        // 2순위: 서버에 저장된 닉네임 (serverNickname)
                        // 3순위: 기본값 ("LumoUser")
                        let realNickname = tempNickname ?? serverNickname ?? "LumoUser"
                        
                        print("✅ 최종 결정된 닉네임: \(realNickname)")
                        
                        // 2. 유저 데이터 생성 또는 업데이트
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
                        // 이 코드가 실행된 후에는 tempNickname이 사라지므로,
                        // 다음 로그인부터는 서버 값을 따라가게 됩니다. (의도된 동작)
                        UserDefaults.standard.removeObject(forKey: "tempNickname")
                    }
                    
                    isLoggedIn = true
                } else {
                    errorMessage = decoded.message ?? "로그인 실패"
                }
            } catch {
                // 실패(400~500) 처리
                if let errorData = try? response.map(APIResponse.self) {
                    errorMessage = errorData.message
                } else {
                    errorMessage = "서버 오류가 발생했습니다."
                }
            }
            
        case .failure(let error):
            // 🔍 여기서 서버가 보낸 진짜 에러 메시지를 확인합니다.
            if let response = error.response {
                let errorBody = String(data: response.data, encoding: .utf8)
                print("❌ [HTTP \(response.statusCode)] 서버 에러 메시지: \(errorBody ?? "없음")")
            } else {
                print("❌ 네트워크 연결 실패: \(error.localizedDescription)")
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

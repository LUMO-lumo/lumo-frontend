//
//    LoginViewModel.swift
//    Lumo
//
//    Created by 김승겸 on 2/2/26.
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
        !email.isEmpty && !password.isEmpty
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
        
        let requestBody = LoginRequest(email: email, password: password)
        
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
                    
                    if let token = decoded.result?.accessToken {
                        // UserInfo 객체 생성
                        let userInfo = UserInfo(accessToken: token, refreshToken: nil)
                        _ = KeychainManager.standard.saveSession(userInfo, for: "userSession")
                    }
                    
                    let user = UserModel(nickname: "LumoUser")
                    modelContext.insert(user)
                    
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
            print("❌ Moya 에러: \(error)")
            errorMessage = "네트워크 연결을 확인해주세요."
        }
        
        isLoading = false
    }
}

/// 로그인 요청 바디
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

//
//  LoginViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {
    
    // MARK: - Input (화면 입력값)
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAutoLogin: Bool = false
    @Published var rememberEmail: Bool = false
    
    // MARK: - Output (화면 상태)
    @Published var errorMessage: String? = nil // 에러 문구
    @Published var isLoading: Bool = false     // 로딩 중 여부
    @Published var isLoggedIn: Bool = false    // 로그인 성공 여부 (화면 이동용)
    
    // 버튼 활성화 로직 (이메일, 비번 입력 시 true)
    var isButtonEnabled: Bool {
        return !email.isEmpty && !password.isEmpty
    }
    
    // MARK: - Business Logic (로그인 함수)
    @MainActor
    func login() async {
        guard isButtonEnabled else { return }
        
        isLoading = true
        errorMessage = nil
        
        let baseURL = AppConfig.baseURL
        guard let url = URL(string: "\(baseURL)/api/member/login") else { return }
        
        // Request 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // 통신 시작
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "서버 오류가 발생했습니다."
                isLoading = false
                return
            }
            
            // 데이터 디코딩
            let decodedResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            if decodedResponse.success {
                // 성공: 토큰 저장 및 화면 전환 트리거
                print("토큰: \(decodedResponse.result?.accessToken ?? "")")
                // UserDefaults.standard.set(decodedResponse.result?.accessToken, forKey: "accessToken")
                self.isLoggedIn = true
            } else {
                // 실패: 서버 메시지 표시
                self.errorMessage = decodedResponse.message
            }
            
        } catch {
            print("에러: \(error)")
            self.errorMessage = "네트워크 연결을 확인해주세요."
        }
        
        isLoading = false
    }
}

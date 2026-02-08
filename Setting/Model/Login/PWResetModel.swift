//
//  PasswordResetModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/8/26.
//

import Foundation

// MARK: - 1. 이메일 확인 요청 데이터 
struct CheckEmailRequest: Encodable {
    let email: String
}

// MARK: - 2. 인증번호 검증 요청 데이터
struct VerifyCodeRequest: Encodable {
    let email: String
    let code: String
}

// MARK: - 3. 비밀번호 변경 요청 데이터
struct ChangePasswordRequest: Encodable {
    let email: String
    let password: String
}

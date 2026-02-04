//
//  SignUpModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//
import Foundation

// MARK: - 공통 API 응답 (모든 API가 이 구조를 따름)
struct APIResponse: Decodable {
    let code: String?       // 예: "MEMBER2005"
    let message: String?
    let success: Bool
    let result: ResponseResult?
}

// result 내부 데이터 (성공 여부 등)
struct ResponseResult: Decodable {
    let isSuccess: Bool
    // accessToken 등은 회원가입 직후엔 안 올 수도 있으니 옵셔널 처리
    let accessToken: String?
}

// MARK: - 회원가입 전송용 데이터 (Body)
struct SignUpRequest: Encodable {
    let email: String
    let password: String
    let username: String
}

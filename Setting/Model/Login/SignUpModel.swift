//
//  SignUpModel.swift
//  Lumo
//
//  Created by 김승겸 on 2/2/26.
//
import Foundation

// MARK: - 공통 API 응답 
struct APIResponse: Decodable {
    let code: String?
    let message: String?
    let success: Bool
    let result: ResponseResult?
}

// result 내부 데이터 (성공 여부 등)
struct ResponseResult: Decodable {
    let isSuccess: Bool
    let accessToken: String?
    let username: String?
}

// MARK: - 회원가입 전송용 데이터 (Body)
struct SignUpRequest: Encodable {
    let email: String
    let password: String
    let username: String
}

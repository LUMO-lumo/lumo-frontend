//
//  UserTarget.swift
//  Lumo
//
//  Created by 김승겸 on 2/7/26.
//

//
//  UserTarget.swift
//  Lumo
//
//  Created by 김승겸 on 2/7/26.
//

import Alamofire
import Foundation
import Moya

enum UserTarget {
    // 1. 이메일 중복 체크 (GET)
    case checkEmailDuplicate(email: String)
    
    // 2. 인증 번호 요청 (POST + Query)
    case requestVerificationCode(email: String)
    
    // 3. 인증 번호 검증 (POST + Query)
    case verifyCode(email: String, code: String)
    
    // 4. 회원가입 (POST + JSON Body)
    case signUp(request: SignUpRequest)
    
    // 5. 로그인 (POST + JSON Body)
    case login(request: LoginRequest)
}

extension UserTarget: TargetType {
    
    // 기본 도메인 주소
    var baseURL: URL {
        // AppConfig.baseURL이 "http://..." 형태라고 가정
        return URL(string: AppConfig.baseURL)!
    }
    
    // 각 API의 경로
    var path: String {
        switch self {
        case .checkEmailDuplicate:      return "/api/member/email-duplicate"
        case .requestVerificationCode:  return "/api/member/request-code"
        case .verifyCode:               return "/api/member/verify-code"
        case .signUp:                   return "/api/member/signin"
        case .login:                    return "/api/member/login"
        }
    }
    
    // 통신 방식 (GET / POST 등)
    var method: Moya.Method {
        switch self {
        case .checkEmailDuplicate:
            return .get
        default:
            return .post
        }
    }
    
    // 데이터 전송 방식 (QueryString vs JSON Body)
    var task: Task {
        switch self {
        // GET 방식 - 쿼리 파라미터
        case .checkEmailDuplicate(let email):
            return .requestParameters(
                parameters: ["email": email],
                encoding: URLEncoding.queryString
            )
            
        // POST 방식이지만, 데이터를 URL 뒤에 붙이는 특이 케이스 (Query Parameter)
        case .requestVerificationCode(let email):
            return .requestParameters(
                parameters: ["email": email],
                encoding: URLEncoding.queryString
            )
            
        case .verifyCode(let email, let code):
            return .requestParameters(
                parameters: ["email": email, "code": code],
                encoding: URLEncoding.queryString
            )
            
        // POST 방식 - 일반적인 JSON Body 전송
        case .signUp(let request):
            return .requestJSONEncodable(request)
            
        case .login(let request):
            return .requestJSONEncodable(request)
        }
    }
    
    // 헤더 설정
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}

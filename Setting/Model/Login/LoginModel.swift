import Foundation

// API 응답 전체를 감싸는 래퍼
struct LoginResponse: Decodable {
    let code: String        // 예: "MEMBER2005"
    let message: String     // 예: "로그인 요청 성공입니다."
    let success: Bool
    let result: LoginResultData? // 성공 시 데이터, 실패 시 nil일 수 있으므로 옵셔널
}

// 'result' 내부의 데이터
struct LoginResultData: Decodable {
    let isSuccess: Bool
    let accessToken: String
}

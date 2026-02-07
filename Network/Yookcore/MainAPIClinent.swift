//
//  APIConstants.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.

//URLSession을 감싸서 실제 HTTP 요청을 수행하는 싱글톤 클래스
//request를 이용하는 역활
import Foundation
import Moya
import Alamofire

// 실제로 서버에 전송을 수행하고 응답을 받는 공통 엔진입니다.
//
class YookAPIClient<T: TargetType> {
    private let provider = MoyaProvider<T>()

    func request<D: Decodable>(_ target: T, completion: @escaping (Result<D, YookAPIError>) -> Void) {
        //Moya 실행 요청
        provider.request(target) { result in
            switch result {
            case .success(let response):
                // 서버 상태 코드가 정상 범위인지 확인합니다.
                guard (200...299).contains(response.statusCode) else {
                    completion(.failure(.serverError(response.statusCode)))
                    return
                }
                // JSON 데이터를 앱의 모델로 변환합니다.
                do {
                    let decoded = try JSONDecoder().decode(D.self, from: response.data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(.decodingError))
                }
            case .failure(let error):
                completion(.failure(.unknownError(error)))
            }
        }
    }
}

//
//  MainAPIClient.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.

import Foundation
import Moya
import Alamofire


class MainAPIClient<T: TargetType> {
    private let provider = MoyaProvider<T>()


    func request<D: Codable>(_ target: T, completion: @escaping (Result<D, MainAPIError>) -> Void) {
        
        provider.request(target) { result in
            switch result {
            case .success(let response):
                guard (200...299).contains(response.statusCode) else {
                    completion(.failure(.serverError(response.statusCode)))
                    return
                }
                
                do {
                    let wrapper = try JSONDecoder().decode(MainAPIResponse<D>.self, from: response.data)
                    
                    if wrapper.success {
                        if let data = wrapper.result {
                            completion(.success(data))
                        } else {
                            completion(.failure(.decodingError))
                        }
                    } else {
                        completion(.failure(.logicError(code: wrapper.code, message: wrapper.message)))
                    }
                    
                } catch {
                    print("Decoding Error: \(error)")
                    let responseString = String(data: response.data, encoding: .utf8)
                    print("원본 데이터: \(responseString ?? "nil")")
                    
                    completion(.failure(.decodingError))
                }
                
            case .failure(let error):
                completion(.failure(.unknownError(error)))
            }
        }
    }
}

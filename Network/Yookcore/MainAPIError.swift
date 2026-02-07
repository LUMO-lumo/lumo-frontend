//
//  YookAPIError.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.

//네트워크 오류, 파싱 오류 등 커스텀 에러 타입 정의
//Enum을 이용하는 역활
import Foundation
import Alamofire

enum YookAPIError: Error {
    case invalidURL
    case decodingError
    case serverError(Int)
    case unknownError(Error)
}

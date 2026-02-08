//
//  MainAPIError.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.

import Foundation
import Alamofire


enum MainAPIError: Error {
    case invalidURL
    case decodingError
    case serverError(Int)
    case unknownError(Error)
    
    // 서버 로직 에러
    case logicError(code: String, message: String)
}

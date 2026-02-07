//
//  YookEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.
//

//모든 API 엔드포인트가 따라야 할 프로토콜 정의
//공통 프로토콜, HTTP Method, Path, Parameter을 작성을 하는 역활
import Foundation
import Moya

// 모든 Endpoint 파일이 상속받을 공통 규격입니다.
protocol YookEndpoint: TargetType { }

extension YookEndpoint {
    var baseURL: URL { URL(string: YookAPIConstants.baseURL)! }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
}

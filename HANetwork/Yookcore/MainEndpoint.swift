//
//  MainEndpoint.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/6/26.
//

import Foundation
import Moya


protocol MainEndpoint: TargetType { }

extension MainEndpoint {
    var baseURL: URL { return URL(string: AppConfig.baseURL)! }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
}

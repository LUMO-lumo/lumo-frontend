//
//  CommonResponse.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/8/26.
//

import Foundation
import Combine
import SwiftUI
import Moya

struct MainAPIResponse<T: Codable>: Codable {
    let code: String
    let message: String
    let result: T?      // 성공 시 데이터 (없을 수도 있으니 옵셔널)
    let success: Bool
}

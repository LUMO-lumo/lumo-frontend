//
//  TokenResponse.swift
//  Lumo
//
//  Created by 김승겸 on 2/10/26.
//

import Foundation

struct TokenResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: UserInfo
}

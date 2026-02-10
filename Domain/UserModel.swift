//
//  UserModel.swift
//  Lumo
//
//  Created by 김승겸 on 1/16/26.
//

import Foundation
import SwiftData

@Model
class UserModel {
    var nickname: String
    
    init(nickname: String) {
        self.nickname = nickname
    }
}

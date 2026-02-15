//
//  FeedbackModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/15/26.
//

import Foundation

struct FeedbackRequest: Codable {
    var title: String
    var content: String
    var email: String
}

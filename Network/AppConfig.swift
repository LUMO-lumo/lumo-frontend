//
//  AppConfig.swift
//  Lumo
//
//  Created by 김승겸 on 2/4/26.
//

import Foundation

enum AppConfig {
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist 없음")
        }
        return dict
    }()
    
    static let baseURL: String = {
        guard let baseURL = AppConfig.infoDictionary["BASE_URL"] as? String else {
            fatalError()
        }
        return baseURL
    }()
}

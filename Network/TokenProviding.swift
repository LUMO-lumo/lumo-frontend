//
//  TokeProviding.swift
//  Lumo
//
//  Created by 김승겸 on 2/9/26.
//

import Foundation

protocol TokenProviding {
    var accessToken: String? { get set }
    func refreshToken(completion: @escaping (String?, Error?) -> Void)
} 

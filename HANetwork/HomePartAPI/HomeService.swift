//
//  HomeService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation

class HomeService {
    
    private let client = MainAPIClient<HomeEndpoint>()
    
    func fetchHomeData(
        today: String,
        completion: @escaping (Result<HomeDTO, MainAPIError>) -> Void
    ) {
        // Endpoint에 today 전달
        client.request(.getHomeInfo(today: today), completion: completion)
    }
}

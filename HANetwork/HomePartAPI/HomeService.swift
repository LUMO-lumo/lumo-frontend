//
//  HomeService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//

import Foundation

class HomeService {
    private let client = MainAPIClient<HomeEndpoint>()

    // HomeModel.swift에 정의된 HomeDTO를 반환 타입으로 사용
    func fetchHomeData(completion: @escaping (Result<HomeDTO, MainAPIError>) -> Void) {
        client.request(.getHomeInfo, completion: completion)
    }
}

//
//  HomeService.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/7/26.
//


import Foundation

// 임시 연결을 위한 빈 모델입니다. 나중에 실제 DTO 파일로 대체하세요.
struct HomeResponse: Decodable {}

class HomeService {
    private let client = YookAPIClient<HomeEndpoint>()

    func fetchHomeData(completion: @escaping (Result<HomeResponse, YookAPIError>) -> Void) {
        // 이제 HomeResponse가 정의되어 있으므로 Generic parameter 'D' 추론 에러가 사라집니다.
        client.request(.getHomeInfo, completion: completion)
    }
}

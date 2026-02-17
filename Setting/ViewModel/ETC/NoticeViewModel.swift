//
//  NoticeViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
// ViewModels/NoticeViewModel.swift

import Foundation
import Moya
import SwiftUI // @Observable 사용을 위해 필요

@Observable
class NoticeViewModel {
    // MARK: - Properties
    var notices: [Notice] = []       // 화면에 뿌려줄 데이터
    var noticeDetail: Notice? = nil
    var isLoading: Bool = false      // 로딩 스피너 제어용
    var errorMessage: String? = nil  // 에러 발생 시 알림용
    var searchText: String = ""      // 검색창과 바인딩
    
    private let provider = MoyaProvider<NoticeTarget>()
    
    // MARK: - Methods
    
    /// 공지사항 목록 조회 (검색어가 있으면 검색, 없으면 전체 조회)
    func fetchNotices() {
        self.isLoading = true
        self.errorMessage = nil
        
        // 검색어가 비어있으면 nil, 있으면 값 전달
        let keywordArg: String? = searchText.isEmpty ? nil : searchText
        
        provider.request(.showNotice(keyword: keywordArg)) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let response):
                do {
                    // 1. 상태 코드 확인 (200~299 성공)
                    _ = try response.filterSuccessfulStatusCodes()
                    
                    // 2. 데이터 디코딩
                    let decodedResponse = try JSONDecoder().decode(NoticeResponse.self, from: response.data)
                    
                    // 3. 성공 여부 확인 (API 스펙의 success 필드 활용)
                    if decodedResponse.success {
                        self.notices = decodedResponse.result
                    } else {
                        self.errorMessage = decodedResponse.message
                    }
                    
                } catch {
                    print("디코딩 에러: \(error)")
                    self.errorMessage = "데이터를 불러오는데 실패했습니다."
                }
                
            case .failure(let error):
                print("네트워크 에러: \(error.localizedDescription)")
                self.errorMessage = "서버 연결 상태를 확인해주세요."
            }
        }
    }
        
        // 상세 조회 함수
        func fetchNoticeDetail(noticeId: Int) {
            self.isLoading = true
            self.errorMessage = nil
            
            provider.request(.showNoticeDetail(noticeId: noticeId)) { [weak self] result in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    do {
                        _ = try response.filterSuccessfulStatusCodes()
                        // NoticeDetailResponse로 디코딩
                        let decodedData = try JSONDecoder().decode(NoticeDetailResponse.self, from: response.data)
                        
                        if decodedData.success {
                            self.noticeDetail = decodedData.result
                        } else {
                            self.errorMessage = decodedData.message
                        }
                    } catch {
                        print("상세 조회 디코딩 에러: \(error)")
                        self.errorMessage = "상세 내용을 불러오지 못했습니다."
                    }
                    
                case .failure(let error):
                    print("네트워크 에러: \(error)")
                    self.errorMessage = "서버 연결에 실패했습니다."
                }
            }
        }
}

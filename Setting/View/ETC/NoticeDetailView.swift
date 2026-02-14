//
//  NoticeDetailView.swift
//  Lumo
//
//  Created by 정승윤 on 2/14/26.
//

import SwiftUI

struct NoticeDetailView: View {
    let noticeId: Int // 목록에서 넘겨받을 ID
    @State private var viewModel = NoticeViewModel()
    @Environment(\.dismiss) private var dismiss // 뒤로가기 버튼용
    
    var body: some View {
        VStack(spacing: 0) {
            // 2. 컨텐츠 영역
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let notice = viewModel.noticeDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // 상단 정보 (타입, 날짜)
                        Text(notice.type)
                            .font(.Body2)
                            .foregroundColor(.main300)
                    
                        
                        Text(notice.formattedDate)
                            .font(.Body3)
                            .foregroundColor(.gray700)
                        
                        // 제목
                        Text(notice.title)
                            .font(.Body1)
                            .foregroundStyle(Color.primary)
                        
                        Divider() // 구분선
                        
                        // 내용 (content)
                        Text(notice.content ?? "내용이 없습니다.")
                            .font(.Body2)
                            .foregroundStyle(Color.primary)
                            .lineSpacing(6) // 줄간격 살짝 띄우기
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24) // 전체 여백
                }
            } else {
                // 로딩 끝났는데 데이터가 없는 경우 (에러 등)
                Spacer()
                Text("내용을 불러올 수 없습니다.")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .topNavigationBar(title: "공지사항 상세")
        .navigationBarHidden(true) // 기본 네비바 숨김
        .onAppear {
            // 화면 진입 시 ID로 상세 내용 요청
            viewModel.fetchNoticeDetail(noticeId: noticeId)
        }
    }
}

#Preview {
    NoticeDetailView(noticeId: 1)
}

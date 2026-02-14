//
//  NoticeView.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import SwiftUI

struct NoticeView: View {
    // ViewModel 인스턴스 생성
    @State private var viewModel = NoticeViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // 검색창
                HStack {
                    TextField("", text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .onSubmit {
                            viewModel.fetchNotices() // 키보드 엔터 눌렀을 때 실행
                        }
                    
                    // 2. 내부 버튼 (돋보기 아이콘)
                    Button(action: {
                        viewModel.fetchNotices()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray) // 아이콘 색상
                    }
                }
                .padding(.horizontal, 16) // 내부 좌우 여백
                .padding(.vertical, 12)   // 내부 상하 여백
                .background(Color.gray.opacity(0.1)) // 🔥 3. 전체 회색 배경 설정
                .cornerRadius(12) // 4. 모서리 둥글게
                .padding(.horizontal)
                // 로딩 중일 때
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                // 데이터가 없을 때
                else if viewModel.notices.isEmpty {
                    Spacer()
                    Text("등록된 공지사항이 없습니다.")
                        .foregroundColor(.gray)
                    Spacer()
                }
                // 리스트 출력
                else {
                    List(viewModel.notices) { notice in
                        ZStack {
                            NavigationLink(destination: NoticeDetailView(noticeId: notice.id)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(notice.type)
                                        .font(.Body2)
                                        .foregroundStyle(Color.main300)
                                    
                                    Text(notice.title)
                                        .font(.Body1)
                                    
                                    Text(notice.formattedDate)
                                        .font(.Body3)
                                        .foregroundColor(.gray700)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .topNavigationBar(title: "공지사항")
        .navigationBarHidden(true)
        .onAppear {
            // 화면 진입 시 데이터 로드
            viewModel.fetchNotices()
        }
        .alert("알림", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NoticeView()
}

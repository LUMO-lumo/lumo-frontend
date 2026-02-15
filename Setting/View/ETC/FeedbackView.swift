//
//  FeedbackView.swift
//  Lumo
//
//  Created by 정승윤 on 2/15/26.
//

import SwiftUI

struct FeedbackView: View {
    @State private var viewModel = FeedbackViewModel()
    @Environment(\.dismiss) private var dismiss // 화면 닫기용
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. 입력 폼 영역
            ScrollView {
                VStack(spacing: 10) {
                    
                    // 제목 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("제목")
                            .font(.headline)
                        TextField("제목을 입력해주세요", text: $viewModel.title)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // 이메일 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이메일")
                            .font(.headline)
                        TextField("답변 받을 이메일을 입력해주세요", text: $viewModel.email)
                            .keyboardType(.emailAddress) // 이메일 키보드
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .autocapitalization(.none)
                    }
                    
                    // 내용 입력 (TextEditor 사용)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("내용")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            if viewModel.content.isEmpty {
                                Text("내용을 입력해주세요")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                            }
                            
                            TextEditor(text: $viewModel.content)
                                .frame(height: 200) // 높이 지정
                                .padding(4)
                                .background(Color.gray.opacity(0.1)) // 배경색이 잘 안 먹힐 수 있어 아래 overlay나 background 처리 필요
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    viewModel.sendFeedback()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("의견보내기")
                                .font(.Subtitle3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValid ? Color.main300 : Color.gray500) // 입력 다 안하면 회색
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isValid || viewModel.isLoading) // 비활성화 처리
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            // 2. 전송 버튼
            
            
        }
        .topNavigationBar(title: "의견 보내기") // 기존 커스텀 네비게이션 사용
        .navigationBarHidden(true)
        // 전송 성공 시 화면 닫기
        .onChange(of: viewModel.isSuccess) { oldValue, newValue in
            // newValue가 true(성공)일 때만 화면을 닫습니다.
            if newValue {
                dismiss()
            }
        }
        // 에러 알림
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
    FeedbackView()
}

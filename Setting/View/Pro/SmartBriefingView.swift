//
//  SmartBriefingView.swift
//  Lumo
//
//  Created by 정승윤 on 2/5/26.
//

import SwiftUI

struct SmartBriefingView: View {
    @State private var viewModel = SmartBriefingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {

            ZStack(alignment: .leading) {
           
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray200)
                    .frame(height: 211)
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("스마트 브리핑이란?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.main300)
                    
                    Text("오늘의 할 일을 바탕으로 자연스럽게\n정리된 구어체 브리핑을 제공해요.\n마치 누군가와 오늘의 일정을 정리해서\n말해주는 것처럼 들려줘요")
                        .font(.Body1)
                        .lineSpacing(4)
                        .foregroundStyle(Color.gray700)
                }
                .padding(.horizontal, 20)
            }
            
            HStack {
                Toggle("스마트 브리핑 활성화", isOn: $viewModel.smartBriefingEnabled)
                    .font(.Subtitle3)
                    .foregroundStyle(Color.gray800)
                    .tint(Color.main300)
            }
            .background(Color.white)
        Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .topNavigationBar(title: "스마트 브리핑")
        .navigationBarHidden(true)
        .onChange(of: viewModel.smartBriefingEnabled) { oldValue, newValue in
            print("토글 상태: \(newValue)")
            viewModel.updateSmartBriefing(isEnabled: newValue)
        }
    }
}

#Preview {
    SmartBriefingView()
}

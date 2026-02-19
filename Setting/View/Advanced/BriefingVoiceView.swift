//
//  BriefingVoiceView.swift
//  Lumo
//
//  Created by 정승윤 on 2/5/26.
//

import SwiftUI

struct BriefingVoiceView: View {
    @State private var viewModel = BriefingVoiceViewModel()
    @State private var proAlert = false
    @Environment(\.dismiss) private var dismiss
    
    let options = ["WOMAN", "MAN", "PRO"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(options, id: \.self) { voice in
                    voiceRow(for: voice)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
        .topNavigationBar(title: "브리핑 목소리")
        .navigationBarHidden(true)
        .alert("Pro 버전으로 업그레이드 하시겠어요?", isPresented: $proAlert) {
            Button("아니요", role: .cancel) { }
            Button("네") {
                print("Pro 업그레이드 시도")
            }
        } message: {
            Text("Pro 버전에서는 원하는 목소리를 포함해서\n더 많은 기능을 사용할 수 있어요.")
                .font(.Body3)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func voiceRow(for voice: String) -> some View {
        Button(action: {
            if voice == "PRO" {
                proAlert = true
            } else {
                viewModel.updateVoice(voice: voice)
            }
        }) {
            HStack(spacing: 16) {
                // 목소리 아바타 이미지
                ZStack {
                    Circle()
                        .foregroundColor(.gray300)
                        .frame(width: 60, height: 60)
                    
                    Image(getVoiceImageName(for: voice))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                }
                
                // 목소리 이름
                Text(getVoiceDisplayName(for: voice))
                    .foregroundColor(.primary)
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                // 커스텀 라디오 버튼
                selectionIndicator(isSelected: viewModel.selectedVoice == voice)
            }
            .padding(.vertical, 5)
        }
    }
    
    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.main300 : Color.gray, lineWidth: 1)
                .frame(width: 16, height: 16)
            
            if isSelected {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.main300)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getVoiceImageName(for voice: String) -> String {
        switch voice {
        case "WOMAN": return "Woman"
        case "MAN": return "Man"
        default: return "Pro"
        }
    }
    
    private func getVoiceDisplayName(for voice: String) -> String {
        switch voice {
        case "WOMAN": return "여자"
        case "MAN": return "남자"
        default: return "Pro"
        }
    }
}

#Preview {
    BriefingVoiceView()
}

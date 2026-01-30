//
//  MissionAlarmSettingView.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation
import SwiftUI

struct MissionAlarmSettingView: View {
    @State private var viewModel = MissionAlarmSettingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let options = [60, 50, 40, 30, 20, 10]

    var body: some View {
        // 1. 상단 네비게이션 바
        ZStack {
            Text("미션 알람 설정")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)

            
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .background(Color.white)
        
        Spacer().frame(height:32)
        
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(options, id: \.self) { seconds in
                    Button(action: {
                        viewModel.updateGlobalMissionDuration(seconds: seconds)
                    }) {
                        HStack(spacing: 10) {
                            if viewModel.selectedSeconds == seconds {
                                ZStack{
                                    Image(systemName: "circle")
                                        .foregroundColor(.main300)
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.main300)
                                    
                                }
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                            Text(seconds == 60 ? "1분" : (seconds == 20 ? "20초 (기본)" : "\(seconds)초"))
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("미션 알람 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MissionAlarmSettingView()
}

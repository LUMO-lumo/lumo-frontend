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
        
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(options, id: \.self) { seconds in
                    Button(action: {
                        viewModel.updateMissionAlarmTime(seconds: seconds)
                    }) {
                        HStack(spacing: 10) {
                            ZStack{
                                Circle()
                                    .stroke(viewModel.selectedSeconds == seconds ? Color.main300 : Color.gray, lineWidth: 1)
                                    .frame(width:16, height:16)
                                    .foregroundColor(.main300)
                                if viewModel.selectedSeconds == seconds {
                                    Circle()
                                        .frame(width:8, height:8)
                                        .foregroundColor(.main300)
                                }
                            }
                            
                            Text(seconds == 60 ? "1분" : (seconds == 20 ? "20초 (기본)" : "\(seconds)초"))
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
        .topNavigationBar(title: "미션 알람 설정")
        .navigationBarHidden(true)
    }
}

#Preview {
    MissionAlarmSettingView()
}

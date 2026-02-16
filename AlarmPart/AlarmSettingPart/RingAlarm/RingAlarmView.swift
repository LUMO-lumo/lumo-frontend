//
//  AlarmPlayingOverlay.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/15/26.
//

import SwiftUI

struct AlarmPlayingOverlay: View {
    @StateObject private var alarmManager = AlarmKitManager.shared
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // 배경: 검은색 반투명
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 알람 아이콘 애니메이션
                Image(systemName: "alarm.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white)
                    .scaleEffect(animateIcon ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateIcon)
                    .onAppear {
                        animateIcon = true
                    }
                
                VStack(spacing: 16) {
                    Text("알람이 울리고 있습니다")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("일어나서 미션을 수행하세요!")
                        .font(.body)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                // 알람 끄기 버튼
                Button(action: {
                    alarmManager.stopAlarmSound()
                }) {
                    Text("알람 끄기")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(hex: "F55641"))
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .zIndex(999) // 가장 위에 표시
    }
}

#Preview {
    AlarmPlayingOverlay()
}

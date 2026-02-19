//
//  DailyRoutineCardView.swift
//  Lumo
//
//  Created by 김승겸 on 1/22/26.
//
import SwiftUI
import SwiftData

struct RoutineCardView: View {
    var task: RoutineTask
    var onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // 연속 달성 배지 (2회 이상일 때만 표시)
                if task.currentStreak > 1 {
                    Text("연속달성 \(task.currentStreak)회")
                        .font(.pretendardSemiBold10)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(hex: "F55641"))
                        .cornerRadius(4)
                }
                
                // 루틴 이름
                Text(task.title)
                    .font(.Subtitle3)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // 체크 버튼 (토글)
            Button {
                onToggle()
            } label: {
                Image(task.isCompleted ? "checkCompleted" : "checkNotCompleted")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 16)
            }
            // 버튼의 터치 영역 확장
            // 이미지가 작더라도 주변 빈 공간을 눌러도 반응
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "DDE1E8"), lineWidth: 1)
        )
    }
}

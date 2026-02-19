//
//  Slider.swift
//  Lumo
//
//  Created by 정승윤 on 2/13/26.
//

import SwiftUI

struct CustomStepSlider: View {
    // 바인딩으로 상위 뷰(ViewModel)와 데이터 공유
    @Binding var selectedIndex: Int
    
    let steps = ["하", "중", "상"]
    let activeColor = Color(red: 0.8, green: 0.4, blue: 0.3)
    let inactiveColor = Color.gray.opacity(0.3)
    
    var body: some View {
        VStack(spacing: 12) {
            
            // 1. 텍스트 라벨 (하, 중, 상)
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Text(steps[index])
                        .font(.Body1)
                        .foregroundColor(selectedIndex == index ? activeColor : .gray)
                        .frame(maxWidth: .infinity, alignment: getAlignment(for: index))
                }
            }
            
            // 2. 슬라이더 트랙과 동그라미
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 회색 배경 선 (전체 트랙)
                    Rectangle()
                        .fill(inactiveColor)
                        .frame(height: 2)
                    
                    // 활성화된 색상 선 (왼쪽부터 현재 위치까지)
                    Rectangle()
                        .fill(activeColor)
                        .frame(width: getWidth(totalWidth: geo.size.width), height: 2)
                    
                    // 동그라미 (Knob)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().fill(Color(hex: "FF9385")) // 테두리
                        )
                        .overlay(
                            Circle().fill(activeColor).frame(width: 8, height: 8) // 내부 점
                        )
                        .shadow(radius: 2)
                        .offset(x: getKnobOffset(totalWidth: geo.size.width))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // 드래그 위치 계산하여 가장 가까운 인덱스로 자석처럼 붙기
                                    let stepWidth = geo.size.width / CGFloat(steps.count - 1)
                                    let index = Int(round(value.location.x / stepWidth))
                                    
                                    // 0 ~ 2 사이로 제한
                                    let newIndex = min(max(index, 0), steps.count - 1)
                                    
                                    if self.selectedIndex != newIndex {
                                        // 햅틱 피드백 추가
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        self.selectedIndex = newIndex
                                    }
                                }
                        )
                }
            }
            .frame(height: 24) // 슬라이더 터치 영역 높이
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - Helper Methods
    
    // 텍스트 정렬 위치 (첫번째는 왼쪽, 중간은 중앙, 끝은 오른쪽)
    private func getAlignment(for index: Int) -> Alignment {
        if index == 0 { return .leading }
        if index == steps.count - 1 { return .trailing }
        return .center
    }
    
    // 활성화된 트랙(선)의 길이 계산
    private func getWidth(totalWidth: CGFloat) -> CGFloat {
        let stepWidth = totalWidth / CGFloat(steps.count - 1)
        return stepWidth * CGFloat(selectedIndex)
    }
    
    // 동그라미의 위치(Offset) 계산
    private func getKnobOffset(totalWidth: CGFloat) -> CGFloat {
        let stepWidth = totalWidth / CGFloat(steps.count - 1)
        let knobSize: CGFloat = 14
        let knobRadius = knobSize / 2
        
        return (stepWidth * CGFloat(selectedIndex)) - knobRadius
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var index: Int = 1
        
        var body: some View {
            VStack {
                Text("현재 값: \(index)")
                    .padding()
                
                CustomStepSlider(selectedIndex: $index)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

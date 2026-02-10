//
//  CustomSlider.swift
//  Lumo
//
//  Created by 김승겸 on 2/1/26.
//

import SwiftUI

// MARK: - 커스텀 슬라이더 구현체
struct CustomSlider: View {
    @Binding var value: Double // 외부와 연동되는 값
    var range: ClosedRange<Double> = 0...100
    var thumbColor: Color = .main300
    var trackHeight: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 회색 배경 트랙
                Rectangle()
                    .foregroundStyle(Color.gray300)
                    .frame(height: trackHeight)
                    .cornerRadius(trackHeight / 2)
                
                // 색상 채워진 트랙
                Rectangle()
                    .foregroundStyle(thumbColor)
                    .frame(width: self.getProgressBarWidth(geometry: geometry), height: trackHeight)
                    .cornerRadius(trackHeight / 2)
                
                // 드래그 가능한 버튼 (Thumb)
                ZStack {
                    
                    Circle()
                        .foregroundStyle(Color(hex: "FF9385"))
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .foregroundStyle(thumbColor)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 20, height: 20) // 터치 영역 및 전체 크기
                .offset(x: self.getThumbOffset(geometry: geometry))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.updateValue(with: value.location.x, geometry: geometry)
                        }
                )
            }
            .frame(height: 14)
        }
    }
    
    // 현재 값에 따른 너비 계산
    private func getProgressBarWidth(geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width
        let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return width * normalizedValue
    }
    
    // 버튼의 위치 계산
    private func getThumbOffset(geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width - 20 // 20은 Thumb의 너비
        let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return width * normalizedValue
    }
    
    // 드래그 시 값 업데이트
    private func updateValue(with locationX: CGFloat, geometry: GeometryProxy) {
        let width = geometry.size.width - 20
        let newValue = Double(locationX / width) * (range.upperBound - range.lowerBound) + range.lowerBound
        // 범위 제한
        value = min(max(newValue, range.lowerBound), range.upperBound)
    }
}

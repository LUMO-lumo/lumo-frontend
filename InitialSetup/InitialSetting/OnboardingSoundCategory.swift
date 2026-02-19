//
//  OnboardingSoundSetupView.swift
//  Lumo
//
//  Created by User on 2/19/26.
//

import SwiftUI

enum OnboardingSoundCategory: String, CaseIterable {
    case calm = "차분한"
    case loud = "시끄러운"
    case motivation = "동기부여"
}

struct OnboardingSoundSetupView: View {
    @Binding var alarmSound: String
    // [수정] 뷰 닫기를 제어할 바인딩 변수
    @Binding var isPresented: Bool
    
    @State private var selectedCategory: OnboardingSoundCategory = .loud
    @State private var selectedSound: String = "비명 소리"
    @State private var volume: Double = 50.0
    
    let soundData: [OnboardingSoundCategory: [String]] = [
        .loud: ["비명 소리", "천둥 번개", "개 짖는 소리", "절규", "뱃고동"],
        .calm: ["평온한 멜로디", "섬의 아침", "플루트 연주", "종소리", "소원"],
        .motivation: ["환희의 록", "황제", "비트 앤 베이스", "침묵 속 노력", "런어웨이"]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 커스텀 네비게이션 바
            ZStack {
                Text("사운드 설정")
                    .font(.system(size: 20, weight: .bold))
                
                HStack {
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gray)
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                }
            }
            .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 30) {
                // 카테고리
                VStack(alignment: .leading, spacing: 12) {
                    Text("알람 음악")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(OnboardingSoundCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    withAnimation {
                                        selectedCategory = category
                                        if let firstSound = soundData[category]?.first {
                                            selectedSound = firstSound
                                        }
                                    }
                                }) {
                                    Text(category.rawValue)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 14)
                                        .background(selectedCategory == category ? Color(hex: "F55641") : Color.clear)
                                        .foregroundStyle(selectedCategory == category ? .white : .gray)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: selectedCategory == category ? 0 : 1)
                                        )
                                }
                            }
                        }
                    }
                }
                
                // 사운드 목록
                VStack(spacing: 24) {
                    let sounds = soundData[selectedCategory] ?? []
                    
                    ForEach(sounds, id: \.self) { sound in
                        Button(action: {
                            selectedSound = sound
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedSound == sound ? "record.circle" : "circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(selectedSound == sound ? Color(hex: "F55641") : Color.gray)
                                
                                Text(sound)
                                    .font(.caption)
                                    .foregroundStyle(Color.primary)
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
                .padding(.horizontal, 19)
                .padding(.vertical, 24)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // 볼륨 슬라이더
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("사운드 크기")
                        Spacer()
                        Text("\(Int(volume))%")
                            .foregroundStyle(Color(hex: "F55641"))
                    }
                    
                    OnboardingCustomSlider(value: $volume, range: 0...100, thumbColor: Color(hex: "F55641"))
                        .frame(height: 20)
                }
            }
            .padding(.top, 19)
            
            Spacer()
            
            Button(action: {
                alarmSound = selectedSound
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("설정하기")
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "F55641"))
                    .cornerRadius(8)
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 24)
        .navigationBarHidden(true)
        .onAppear {
            for (category, sounds) in soundData {
                if sounds.contains(alarmSound) {
                    selectedCategory = category
                    selectedSound = alarmSound
                    break
                }
            }
        }
    }
}

// MARK: - 커스텀 슬라이더
struct OnboardingCustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100
    var thumbColor: Color
    var trackHeight: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .frame(height: trackHeight)
                    .cornerRadius(trackHeight / 2)
                
                Rectangle()
                    .foregroundStyle(thumbColor)
                    .frame(width: self.getProgressBarWidth(geometry: geometry), height: trackHeight)
                    .cornerRadius(trackHeight / 2)
                
                ZStack {
                    Circle()
                        .foregroundStyle(Color(hex: "FF9385"))
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .foregroundStyle(thumbColor)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 20, height: 20)
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
    
    private func getProgressBarWidth(geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width
        let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return width * max(0, normalizedValue)
    }
    
    private func getThumbOffset(geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width - 20
        let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return width * max(0, normalizedValue)
    }
    
    private func updateValue(with locationX: CGFloat, geometry: GeometryProxy) {
        let width = geometry.size.width - 20
        let newValue = Double(locationX / width) * (range.upperBound - range.lowerBound) + range.lowerBound
        value = min(max(newValue, range.lowerBound), range.upperBound)
    }
}

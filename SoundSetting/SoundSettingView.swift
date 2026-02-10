//
//  SoundSettingView.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/1/26.
//

import SwiftUI

// 카테고리 열거형 정의
enum SoundCategory: String, CaseIterable {
    case calm = "차분한"
    case loud = "시끄러운"
    case motivation = "동기부여"
    case notification = "알림음"
}

struct SoundSettingView: View {
    // MARK: - State Properties
    @Environment(\.dismiss) private var dismiss
    
    // 부모 뷰의 데이터를 수정하기 위한 Binding 변수
    @Binding var alarmSound: String
    
    @State private var selectedCategory: SoundCategory = .calm
    @State private var selectedSound: String = "커피한잔의 여유"
    @State private var volume: Double = 50.0 // 0 ~ 100
    
    init(alarmSound: Binding<String>) {
        _alarmSound = alarmSound
    }
    
    // MARK: - Local Dummy Data
    let soundData: [SoundCategory: [String]] = [
        .calm: ["커피한잔의 여유", "빗소리", "숲속의 아침", "잔잔한 피아노"],
        .loud: ["사이렌", "헤비메탈 모닝", "천둥번개", "경적 소리"],
        .motivation: ["록키 주제곡", "박수 갈채", "명언 모음", "승리의 팡파레"],
        .notification: ["딩동댕", "까톡", "기본 알림", "휘파람"]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 커스텀 네비게이션 바
            ZStack {
                Text("사운드 설정")
                    .font(.system(size: 20, weight: .bold))
                
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gray500)
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 30) {
                
                // 알람 음악 카테고리 선택 영역
                VStack(alignment: .leading, spacing: 12) {
                    Text("알람 음악")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(SoundCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    withAnimation {
                                        selectedCategory = category
                                        if let firstSound = soundData[category]?.first {
                                            selectedSound = firstSound
                                            // [추가] 카테고리 변경 시 첫 곡 재생
                                            SoundManager.shared.playPreview(named: selectedSound, volume: volume)
                                        }
                                    }
                                }) {
                                    Text(category.rawValue)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 14)
                                        .background(selectedCategory == category ? Color.main300 : Color.white)
                                        .foregroundStyle(selectedCategory == category ? .white : .gray)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .strokeBorder(Color.gray400, lineWidth: selectedCategory == category ? 0 : 1)
                                        )
                                }
                            }
                        }
                    }
                }
                
                // 사운드 목록 박스
                VStack(spacing: 24) {
                    let sounds = soundData[selectedCategory] ?? []
                    
                    ForEach(sounds, id: \.self) { sound in
                        Button(action: {
                            selectedSound = sound
                            // [추가] 사운드 선택 시 미리듣기 재생
                            SoundManager.shared.playPreview(named: sound, volume: volume)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedSound == sound ? "record.circle" : "circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(selectedSound == sound ? Color.main300 : Color.gray300)
                                
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
                        .strokeBorder(Color.gray300, lineWidth: 1)
                )
                
                // 사운드 크기 (Slider)
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("사운드 크기")
                        Spacer()
                        Text("\(Int(volume))%")
                            .foregroundStyle(Color.main300)
                    }
                    
                    // CustomSlider는 UI만 담당하므로 수정 불필요
                    // 값(volume)이 변하면 아래 onChange에서 감지함
                    CustomSlider(value: $volume, range: 0...100, thumbColor: .main300)
                        .frame(height: 20)
                        // [추가] 슬라이더 값 변경 시 실제 볼륨 조절
                        .onChange(of: volume) { newValue in
                            SoundManager.shared.setVolume(newValue)
                        }
                    
                }
            }
            .padding(.top, 19)
            
            Spacer()
            
            // 하단 설정하기 버튼
            Button(action: {
                alarmSound = selectedSound
                SoundManager.shared.stop() // [추가] 나가면 소리 끔
                dismiss()
            }) {
                Text("설정하기")
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.main300)
                    .cornerRadius(8)
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            for (category, sounds) in soundData {
                if sounds.contains(alarmSound) {
                    selectedCategory = category
                    selectedSound = alarmSound
                    break
                }
            }
        }
        // [추가] 화면이 사라질 때(뒤로가기 등) 소리 멈춤
        .onDisappear {
            SoundManager.shared.stop()
        }
        .padding(.bottom, 50)
    }
}

#Preview {
    SoundSettingView(alarmSound: .constant("커피한잔의 여유"))
}

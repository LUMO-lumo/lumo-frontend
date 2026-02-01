//
//  SoundSettingView.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 2/1/26.
//

import SwiftUI


// 카테고리 열거형 정의 (관리를 편하게 하기 위함)
enum SoundCategory: String, CaseIterable {
    case calm = "차분한"
    case loud = "시끄러운"
    case motivation = "동기부여"
    case notification = "알림음"
}

struct SoundSettingView: View {
    // MARK: - State Properties
    @Environment(\.dismiss) private var dismiss // 뒤로가기 처리를 위한 변수
    
    // [핵심] 부모 뷰의 데이터를 수정하기 위한 Binding 변수
    @Binding var alarmSound: String
    
    @State private var selectedCategory: SoundCategory = .calm
    @State private var selectedSound: String = "커피한잔의 여유" // 기본 선택값
    @State private var volume: Double = 50.0 // 0 ~ 100
    
    // [수정] 기본값(.constant)을 제거했습니다.
    // 이제 부모 뷰에서 호출할 때 반드시 바인딩($)을 전달해야 합니다.
    init(alarmSound: Binding<String>) {
        _alarmSound = alarmSound
    }
    
    // MARK: - Local Dummy Data (API 대용)
    // 실제로는 각 사운드 객체에 ID가 있겠지만, 여기선 String으로 처리
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
                    Spacer() // 버튼을 왼쪽으로 밀어냄
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
                                        // 카테고리 변경 시 해당 카테고리의 첫 번째 곡을 기본 선택
                                        if let firstSound = soundData[category]?.first {
                                            selectedSound = firstSound
                                        }
                                    }
                                }) {
                                    Text(category.rawValue)
                                        //font(.Body1)
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
                    // 선택된 카테고리의 데이터 가져오기 (없으면 빈 배열)
                    let sounds = soundData[selectedCategory] ?? []
                    
                    ForEach(sounds, id: \.self) { sound in
                        Button(action: {
                            // 버튼을 누르면 선택된 사운드 업데이트
                            selectedSound = sound
                        }) {
                            HStack(spacing: 8) {
                                // 선택 여부에 따라 아이콘 변경 (String끼리 비교)
                                Image(systemName: selectedSound == sound ? "record.circle" : "circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(selectedSound == sound ? Color.main300 : Color.gray300)
                                
                                Text(sound)
                                    .font(.caption) // .Body2 대신 기본 폰트 사용 (혹은 커스텀 폰트 유지)
                                    .foregroundStyle(Color.primary)
                                
                                Spacer()
                            }
                            .contentShape(Rectangle()) // 터치 영역 확장
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
                            //.font(.Subtitle2)
                        
                        Spacer()
                        
                        Text("\(Int(volume))%")
                            //.font(.pretendardSemiBold14)
                            .foregroundStyle(Color.main300)
                    }
                    
                    CustomSlider(value: $volume, range: 0...100, thumbColor: .main300)
                        .frame(height: 20) // 터치 영역 높이 확보
                    
                }
            }
            .padding(.top, 19)
            
            
            Spacer()
            
            // 하단 설정하기 버튼
            // 설정하기 누르면 내비게이션로 설정 사운드 반영하면서 옮길 예정
            Button(action: {
                // [수정] 설정 완료 시 부모 뷰의 데이터(alarmSound)를 업데이트
                alarmSound = selectedSound
                print("설정 완료: \(selectedCategory.rawValue) - \(selectedSound), 볼륨: \(Int(volume))")
                dismiss() // 화면 닫기
            }) {
                Text("설정하기")
                    //.font(.Subtitle3)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.main300)
                    .cornerRadius(8)
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 24)
        // [수정] 이 부분을 추가하여 시스템 뒤로가기 버튼을 숨깁니다.
        .navigationBarBackButtonHidden(true)
        // [추가] 화면이 나타날 때 현재 설정된 알람음이 있다면 해당 카테고리와 사운드를 찾아 선택 상태로 동기화
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

#Preview {
    SoundSettingView(alarmSound: .constant("커피한잔의 여유"))
}

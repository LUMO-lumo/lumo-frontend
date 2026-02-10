//
//  OnboardingViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 1/4/26.
//

import Foundation
import Observation
import PhotosUI
import SwiftData
import SwiftUI

// 미션 종류
enum MissionType: String, CaseIterable {
    case math = "math"
    case typing = "typing"
    case ox = "ox"
    case distance = "distance"
    
    // 화면에 보여줄 한글 이름
    var title: String {
        switch self {
        case .math: return "수학 미션"
        case .typing: return "따라쓰기"
        case .ox: return "OX퀴즈"
        case .distance: return "거리 미션"
        }
    }
}

// 온보딩 단계 네비게이션용
enum OnboardingStep: Hashable {
    case initialSetup
//    case alarmSetting
//    case soundSetting
//    case notificationSetting
//    case locationSetting
//    case backgroundSelect
//    case permissionCheck
    case introMission
    case missionSelect
//    case missionPreview(MissionType)
//    case finalComplete
    case home
}

@Observable
class OnboardingViewModel {
    
    // MARK: - Navigation Path
    var path = NavigationPath()
    
    // MARK: - 사용자가 선택 중인 임시 데이터
    var selectedTime: Date = Date()
    var selectedLabel: String = "1교시 있는 날"
    
    var selectedSound: String = "커피한잔의 여유"
    var selectedVolume: Double = 0.5
    
    var selectedMission: MissionType = .math
    
    // 배경 이미지 관련
    var selectedImages: [UIImage] = [] // 실제 화면에 보여줄 이미지들
    var imageSelections: [PhotosPickerItem] = [] {
        didSet {
            loadImage(from: imageSelections)
        }
    }
    
    var nickname: String = ""
    
    // MARK: - Logic
    
    /// PhotosPickerItem을 UIImage로 변환하는 비동기 함수
    private func loadImage(from selections: [PhotosPickerItem]) {
        
        Task {
            var loadedImages: [UIImage] = []
            
            for item in selections {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    loadedImages.append(uiImage)
                }
            }
            
            await MainActor.run {
                self.selectedImages = loadedImages
            }
        }
    }
    
    /// 최종 알람 객체 생성 및 SwiftData 컨텍스트에 저장
    func createFinalAlarm(modelContext: ModelContext) {
        
        // 미션 타입에 따른 Target 설정 규칙
        let finalTarget: String
        
        switch selectedMission {
        case .math:
            // 일반/PRO 공통: AI가 자동으로 난이도 조절하도록 'auto(하)' 설정
            finalTarget = "auto"
            
        case .typing:
            // 온보딩 예시 문구 저장 (나중에 사용자 입력 기능 추가 시 변경 가능)
            finalTarget = "할 수 있다!"
            
        case .distance:
            // 온보딩 거리 예시 (단위: m)
            finalTarget = "100"
            
        case .ox:
            // 상식 퀴즈
            finalTarget = "common_sense"
        }
        
        // 모델 생성
        let newAlarm = AlarmModel (
            time: selectedTime,
            label: selectedLabel,
            soundName: selectedSound,
            soundVolume: selectedVolume,
            missionType: selectedMission.rawValue,
            missionTarget: finalTarget
        )
        
        // 이미지 데이터 변환 및 저장
        if let firstImage = selectedImages.first,
           let imageData = firstImage.jpegData(compressionQuality: 0.8) {
            newAlarm.backgroundImageData = imageData
        }
        
        // DB Insert
        modelContext.insert(newAlarm)
        print("알람 저장 완료: \(newAlarm.missionType) - \(newAlarm.missionTarget)")
    }
}

let onboardingData: [OnboardingItem] = [
    OnboardingItem(
        title: "확실하게 깨워주는 진짜 알람",
        description: "마무리 피곤하고 지쳐도 개운하게",
        imageName: "Logo"
    ),
    OnboardingItem(
        title: "하루의 빛과 모멘텀을 만듭니다",
        description: "AI가 당신의 하루를 깨우고, 달리고, 움직이게 합니다.",
        imageName: "OnBoarding1"
    ),
    OnboardingItem(
        title: "미션으로 확실하게",
        description: "거리 미션, 수학 문제 ox퀴즈, 따라쓰기 등,\n 다양한 미션을 완수하고 확실하게 깨어나세요!",
        imageName: "OnBoarding2"
    ),
    OnboardingItem(
        title: "AI가 브리핑하는 하루",
        description: "미션 성공 후 AI가 오늘 일정을 음성으로 브리핑 해드려요.\n하루를 준비하는 완벽한 시작을 경험해보세요!",
        imageName: "OnBoarding3"
    ),
    OnboardingItem(
        title: "루틴으로 만드는 성장",
        description: "매일의 성과를 기록하고 루틴을 만들어볼까요?\n당신의 성장을 LUMO가 함께할게요!",
        imageName: "OnBoarding4"
    ),
    OnboardingItem(
        title: "당신에게 맞춘 LUMO 만들기",
        description: "당신에게 맞게 설정 후, 알맞은 콘텐츠를 제공드려요.",
        imageName: "OnBoarding5"
    )
]

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
    case soundSetting
    case backgroundSelect
    case permissionCheck
    case introMisison
    case missionSelect
    case missionPreview(MissionType)
    case finalComplete
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
    var selectedImage: UIImage? = nil
    var imageSelection: PhotosPickerItem? = nil {
        didSet {
            loadImage(from: imageSelection)
        }
    }
    
    // MARK: - Logic
    
    /// PhotosPickerItem을 UIImage로 변환하는 비동기 함수
    private func loadImage(from selection: PhotosPickerItem?) {
        guard let selection else { return }
        Task {
            if let data = try? await selection.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = uiImage
                }
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
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            newAlarm.backgroundImageData = imageData
        }
        
        // DB Insert
        modelContext.insert(newAlarm)
        print("알람 저장 완료: \(newAlarm.missionType) - \(newAlarm.missionTarget)")
    }
}

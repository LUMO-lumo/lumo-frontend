//
//
//  SoundManager.swift
//  LUMO_MainDev
//
//  Created by Sound Helper on 2/10/26.
//

import Foundation
import AVFoundation

class SoundManager: NSObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    // 오디오 세션 설정 (무음 모드에서도 소리 나게)
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 오디오 세션 설정 실패: \(error)")
        }
    }
    
    // 사운드 미리듣기 재생
    func playPreview(named soundName: String, volume: Double) {
        // 파일명 매핑 (한글 이름 -> 영어 파일명)
        // 실제 프로젝트에 'coffee.m4a' 등의 파일이 있어야 합니다.
        let fileName: String
        switch soundName {
        case "커피한잔의 여유": fileName = "coffee"
        case "사이렌": fileName = "siren"
        case "빗소리": fileName = "rain"
        default: fileName = "default_sound" // 파일이 없으면 재생 안 됨
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            print("❌ 사운드 파일 없음: \(fileName).m4a")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = Float(volume / 100.0) // 0.0 ~ 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("❌ 재생 실패: \(error)")
        }
    }
    
    // 볼륨 조절 (슬라이더 움직일 때 실시간 반영)
    func setVolume(_ volume: Double) {
        audioPlayer?.volume = Float(volume / 100.0)
    }
    
    // 재생 중지 (화면 나갈 때)
    func stop() {
        audioPlayer?.stop()
    }
}

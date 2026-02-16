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
    
    // MARK: - 파일명 매핑 로직 (AlarmKit 등 외부에서도 사용 가능)
    func getSoundFileName(named soundName: String) -> String? {
        switch soundName {
        // [시끄러운]
        case "비명 소리": return "scream14-6918"
        case "천둥 번개": return "big-thunder-34626"
        case "개 짖는 소리": return "big-dog-barking-112717"
        case "절규": return "desperate-shout-106691"
        case "뱃고동": return "traimory-mega-horn-angry-siren-f-cinematic-trailer-sound-effects-193408" // [수정됨] 실제 파일명 반영
            
        // [차분한]
        case "평온한 멜로디": return "calming-melody-loop-291840"
        case "섬의 아침": return "the-island-clearing-216263"
        case "플루트 연주": return "native-american-style-flute-music-324301"
        case "종소리": return "calm-music-64526" // bell 대체 (파일명 추정)
        case "소원": return "i-wish-looping-tune-225553"
            
        // [동기부여]
        case "환희의 록": return "rock-of-joy-197159"
        case "황제": return "emperor-197164"
        case "비트 앤 베이스": return "basic-beats-and-bass-10791"
        case "침묵 속 노력": return "work-hard-in-silence-spoken-201870"
        case "런어웨이": return "runaway-loop-373063"
            
        default: return nil
        }
    }
    
    // 사운드 미리듣기 재생
    func playPreview(named soundName: String, volume: Double) {
        // 위에서 정의한 매핑 함수 사용
        guard let fileName = getSoundFileName(named: soundName) else {
            print("❌ 매핑된 파일 없음: \(soundName)")
            return
        }
        
        // 확장자는 m4a, mp3, wav 등을 확인해야 합니다. 여기서는 m4a로 가정하거나 mp3로 시도합니다.
        // 스크린샷의 아이콘을 보면 mp3 또는 wav일 가능성이 높습니다. (파일 없으면 nil)
        var soundURL = Bundle.main.url(forResource: fileName, withExtension: "mp3")
        
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: fileName, withExtension: "m4a")
        }
        
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: fileName, withExtension: "wav")
        }

        guard let url = soundURL else {
            print("❌ 사운드 파일 없음 (Bundle): \(fileName)")
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

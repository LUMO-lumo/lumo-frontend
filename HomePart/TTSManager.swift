
//
//  TTSManager.swift
//  LUMO
//
//  Created by 육도연 on 2/19/26.
//

import Foundation
import AVFoundation

class TTSManager: NSObject {
    static let shared = TTSManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            // TTS가 다른 소리(음악 등)를 멈추지 않고 오리발(Duck) 처리하거나, 재생되게 설정
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ TTS Audio Session Error: \(error)")
        }
    }
    
    func play(_ text: String) {
        // 이미 말하고 있다면 중단 후 새로 시작
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR") // 한국어 설정
        utterance.rate = 0.5 // 말하기 속도 (0.0 ~ 1.0, 기본 0.5)
        utterance.pitchMultiplier = 1.0 // 톤 높낮이
        
        synthesizer.speak(utterance)
        print("🗣️ [TTS Started]: \(text)")
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

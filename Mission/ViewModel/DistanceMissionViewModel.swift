//
//  DistanceMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import CoreLocation
import Combine

// CoreLocation은 Main Thread에서 UI와 상호작용하므로 MainActor 권장
@MainActor
class DistanceMissionViewModel: BaseMissionViewModel, CLLocationManagerDelegate {
    
    // MARK: - 고유 프로퍼티
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation? // 이전 위치 저장용
    
    @Published var currentDistance: Double = 0.0
    @Published var targetDistance: Double = 50.0 // 기본값 50m
    
    // UI 표시용 메시지
    @Published var feedbackMessage: String = "목표를 향해 걸어보세요!"
    
    override init(alarmId: Int) {
        super.init(alarmId: alarmId)
        setupLocationManager()
    }
    
    // 위치 권한 및 설정
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 정확도 최상
        locationManager.pausesLocationUpdatesAutomatically = false // 멈춤 방지
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - 1. 시작하기 (Async 변환)
    func start() async {
        print("🚀 [Distance] 미션 시작 요청: GPS 엔진 가동")
        
        // 1. 초기화 및 GPS 우선 가동 (네트워크 늦어도 측정 시작)
        self.currentDistance = 0.0
        self.previousLocation = nil
        self.locationManager.startUpdatingLocation()
        
        do {
            // 2. 부모 API 호출 (await 사용)
            if let result = try await super.startMission() {
                print("🌐 [SERVER] 응답 성공: 목표 거리 \(result.question)m")
                
                // 서버에서 온 질문("50")을 숫자로 변환, 실패 시 기본값 50.0
                if let serverDistance = Double(result.question) {
                    self.targetDistance = serverDistance
                }
            }
        } catch {
            print("⚠️ [SERVER] 시작 실패 (오프라인 모드 동작): \(error)")
            // 에러가 나도 GPS는 이미 켜져 있으므로 미션 수행 가능 (기본값 50m 유지)
            self.errorMessage = "네트워크 연결 실패 (오프라인 모드로 진행)"
        }
    }
    
    // MARK: - 2. 제출하기 (Async 변환)
    func submit() async {
        guard let contentId = contentId else {
            print("❌ contentId가 없습니다.")
            return
        }
        
        // 요청 바디 생성
        let request = MissionSubmitRequest(
            contentId: contentId,
            userAnswer: String(format: "%.1f", currentDistance),
            attemptCount: attemptCount
        )
        
        do {
            // 부모 API 호출 (await 사용)
            let isCorrect = try await super.submitMission(request: request)
            
            if isCorrect {
                self.feedbackMessage = "미션 성공! 🎉"
                self.locationManager.stopUpdatingLocation() // 성공 시 위치 추적 종료
                self.isMissionCompleted = true
            } else {
                self.feedbackMessage = "아직 목표에 도달하지 못했습니다."
            }
        } catch {
            print("❌ 제출 실패: \(error)")
            self.errorMessage = "결과 전송 실패. 다시 시도해주세요."
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    // (Delegate 메서드는 MainActor인 클래스 안이라도 비동기적으로 호출될 수 있어 nonisolated 처리하거나 MainActor 보장 필요)
    // 여기서는 클래스 전체가 @MainActor이므로 안전합니다.
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 정확도가 너무 떨어지는 데이터 무시 (예: 오차 20m 이상이면 무시)
        // 실내 테스트면 이 조건을 좀 완화하거나 주석 처리하세요.
        // guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 20 else { return }
        
        // 1. 이전 위치가 있다면 거리 누적
        if let previous = previousLocation {
            let distanceInMeters = location.distance(from: previous)
            
            // ⭐️ 0.5m 이상 움직였을 때만 누적 (GPS 튐 방지)
            if distanceInMeters > 0.5 {
                currentDistance += distanceInMeters
                print("🚶 이동: +\(String(format: "%.1f", distanceInMeters))m | 누적: \(String(format: "%.1f", currentDistance))m / \(targetDistance)m")
            }
        } else {
            print("📍 첫 위치 고정 완료")
        }
        
        // 2. 현재 위치 갱신
        previousLocation = location
        
        // 3. 목표 달성 체크 (중복 제출 방지)
        if currentDistance >= targetDistance && !isMissionCompleted {
            print("🏁 목표 달성! 자동 제출을 시도합니다.")
            
            // Delegate는 동기 함수이므로, async 함수인 submit()을 부르려면 Task가 필요함
            _Concurrency.Task { [weak self] in
                await self?.submit()
            }
        }
    }
    
    // 권한 변경 감지
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨")
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("🚫 위치 권한 거부됨")
            self.errorMessage = "위치 권한이 필요합니다. 설정에서 켜주세요."
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

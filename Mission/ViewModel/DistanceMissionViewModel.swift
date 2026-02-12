//
//  DistanceMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import CoreLocation
import Combine
import _Concurrency

<<<<<<< HEAD
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
=======
// 제출용 데이터 구조체
struct DistanceMissionSubmitRequest: Codable {
    let contentId: Int
    let currentDistance: Double
    let attemptCount: Int
}

@MainActor
class DistanceMissionViewModel: BaseMissionViewModel, CLLocationManagerDelegate {
    
    // MARK: - Properties (UI Binding)
    @Published var currentDistance: Double = 0.0
    @Published var targetDistance: Double = 50.0 // 기본 목표값
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
>>>>>>> 27da3b1cde125437bac73aa2f7f23063ff9ce779
    
    // MARK: - Internal Properties (Location)
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    
    // MARK: - Mock Mode
    private let isMockMode: Bool = true // 테스트 시 true, 배포 시 false
    
    // MARK: - Initialization
    override init(alarmId: Int) {
        super.init(alarmId: alarmId)
        setupLocationManager()
    }
    
<<<<<<< HEAD
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
=======
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - 1. 미션 시작 (View에서 호출)
    func start() {
        // 1. GPS 엔진 먼저 가동 (서버 응답 대기 시간에도 위치 잡도록)
        self.currentDistance = 0.0
        self.previousLocation = nil
        self.locationManager.startUpdatingLocation()
        print("📡 [GPS] 위치 업데이트 시작")
        
        // [Mock]
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real] - 부모 메서드 호출 (재사용)
        AsyncTask {
            do {
                // "부모님(super), 미션 시작 요청해주세요. 결과는 배열로 주세요."
                let result: [MissionStartResult] = try await super.startMission()
                
                if let firstMission = result.first {
                    self.contentId = firstMission.contentId
                    
                    // 서버에서 "question" 필드에 "50" 같은 숫자를 준다고 가정
                    if let dist = Double(firstMission.question) {
                        self.targetDistance = dist
                        print("✅ [Server] 목표 거리 설정: \(dist)m")
                    } else {
                        print("⚠️ [Server] 목표 거리 파싱 실패, 기본값 사용")
                    }
                }
            } catch {
                self.handleError(error)
            }
        }
    }
    
    // MARK: - 2. 미션 제출 (목표 달성 시 자동 호출)
    func submit() {
        // [Mock]
        if isMockMode {
            checkMockSuccess()
            return
        }
        
        // [Real]
        guard let contentId = contentId else { return }
        
        let body = DistanceMissionSubmitRequest(
            contentId: contentId,
            currentDistance: self.currentDistance,
            attemptCount: self.attemptCount + 1
        )
        
        AsyncTask {
            do {
                // "부모님(super), 제출해주세요."
                let result: MissionSubmitResult = try await super.submitMission(request: body)
                
                self.handleSubmissionResult(
                    isCorrect: result.isCorrect,
                    isCompleted: result.isCompleted
                )
            } catch {
                self.handleError(error)
            }
        }
    }
    
    // MARK: - Helper (UI Logic)
    private func handleSubmissionResult(isCorrect: Bool, isCompleted: Bool) {
        self.isCorrect = isCorrect
        self.showFeedback = true
        
        if isCorrect {
            self.feedbackMessage = "미션 성공!"
            print("🎉 정답! 1.5초 후 알람 해제")
            
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                await super.dismissAlarm()
            }
        } else {
            self.feedbackMessage = "실패... 다시 시도하세요."
            
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.showFeedback = false
                // 실패 시 위치 추적 재개 필요하다면 여기서 처리
>>>>>>> 27da3b1cde125437bac73aa2f7f23063ff9ce779
            }
        }
    }
    
<<<<<<< HEAD
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
=======
    // 에러 처리 (MathViewModel과 동일)
    private func handleError(_ error: Error) {
        if let missionError = error as? MissionError {
            switch missionError {
            case .serverError(let message):
                self.errorMessage = message
            }
        } else {
            self.errorMessage = "오류가 발생했습니다."
        }
        print("❌ Error: \(error)")
    }
    
    // MARK: - CLLocationManagerDelegate
    // Delegate 메서드는 시스템 스레드에서 호출되므로 nonisolated 처리 후 MainActor로 진입
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        AsyncTask { @MainActor in
            guard let location = locations.last else { return }
            
            // 1. 이전 위치가 있으면 거리 계산
            if let previous = previousLocation {
                let delta = location.distance(from: previous)
                
                // 0.5m 이상 이동했을 때만 누적 (튀는 값 방지)
                if delta > 0.5 {
                    currentDistance += delta
                    print("🏃‍♂️ 이동: +\(String(format: "%.1f", delta))m | 현재: \(String(format: "%.1f", currentDistance))m")
                }
            }
            
            // 2. 현재 위치 갱신
            previousLocation = location
            
            // 3. 목표 달성 체크
            if currentDistance >= targetDistance {
                // 중복 제출 방지 체크
                if !isMissionCompleted && !isLoading {
                    print("🏁 목표 달성! 자동 제출")
                    self.locationManager.stopUpdatingLocation() // 위치 추적 중지
                    submit()
                }
            }
>>>>>>> 27da3b1cde125437bac73aa2f7f23063ff9ce779
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        AsyncTask { @MainActor in
            switch self.locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ 위치 권한 허용됨")
                self.locationManager.startUpdatingLocation()
            case .denied, .restricted:
                self.errorMessage = "위치 권한을 허용해주세요."
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Mock Helpers
    private func setupMockData() {
        self.isLoading = true
        print("🧪 [Mock] 거리 미션 시작 (타겟: 30m)")
        
        AsyncTask {
            try? await AsyncTask.sleep(nanoseconds: 500_000_000)
            self.contentId = 888
            self.targetDistance = 30.0
            self.isLoading = false
            
            // Mock 모드에서는 자동으로 거리가 차오르는 시뮬레이션
            self.simulateMockWalking()
        }
    }
    
    private func simulateMockWalking() {
        AsyncTask {
            while currentDistance < targetDistance {
                try? await AsyncTask.sleep(nanoseconds: 500_000_000) // 0.5초마다
                self.currentDistance += 5.0
                print("🧪 [Mock Walking] \(currentDistance)m / \(targetDistance)m")
            }
            // 목표 도달 시 제출
            self.submit()
        }
    }
    
    private func checkMockSuccess() {
        self.handleSubmissionResult(isCorrect: true, isCompleted: true)
    }
}

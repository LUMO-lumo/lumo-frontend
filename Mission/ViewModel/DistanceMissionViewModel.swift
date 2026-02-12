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
            }
        }
    }
    
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

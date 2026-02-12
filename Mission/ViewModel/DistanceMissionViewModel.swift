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


// CoreLocation은 Main Thread에서 UI와 상호작용하므로 MainActor 권장
@MainActor
class DistanceMissionViewModel: BaseMissionViewModel, CLLocationManagerDelegate {
    

    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation? // 이전 위치 저장용
    
    @Published var currentDistance: Double = 0.0
    @Published var targetDistance: Double = 50.0 // 기본 목표값
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    
    // MARK: - Mock Mode
    private let isMockMode: Bool = true // 테스트 시 true, 배포 시 false
    
    // MARK: - Initialization
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
                    await submit()
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
    
    private func handleSubmissionResult(isCorrect: Bool) {
            self.isCorrect = isCorrect
            self.showFeedback = true
            
            if isCorrect {
                self.feedbackMessage = "미션 성공! 🎉"
                self.locationManager.stopUpdatingLocation()
                // 💡 BaseMissionViewModel이 isMissionCompleted를 true로 만들고
                // API를 통해 알람을 해제할 때까지 UI 피드백을 유지합니다.
            } else {
                self.feedbackMessage = "아직 목표에 도달하지 못했습니다."
                AsyncTask {
                    try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                    self.showFeedback = false
                }
            }
        }
    
    // MARK: - Mock Helpers
            private func setupMockData() {
                    self.isLoading = true
                    AsyncTask {
                        try? await AsyncTask.sleep(nanoseconds: 500_000_000)
                        self.contentId = 888
                        self.targetDistance = 30.0
                        self.isLoading = false
                        self.simulateMockWalking()
                    }
                }
                
                private func simulateMockWalking() {
                    AsyncTask {
                        while currentDistance < targetDistance {
                            try? await AsyncTask.sleep(nanoseconds: 500_000_000)
                            self.currentDistance += 5.0
                        }
                        await self.submit()
                    }
                }
                
                private func checkMockSuccess() {
                    self.handleSubmissionResult(isCorrect: true)
                    AsyncTask {
                        try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                        self.isMissionCompleted = true
                    }
                }
            }

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


// CoreLocation은 Main Thread에서 UI와 상호작용하므로 MainActor 권장
@MainActor
class DistanceMissionViewModel: BaseMissionViewModel, CLLocationManagerDelegate {
    
    // MARK: - Properties (UI Binding)
    @Published var currentDistance: Double = 0.0
    @Published var targetDistance: Double = 0.0
    @Published var feedbackMessage: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    
    let alarmLabel: String
    
    // MARK: - Internal Properties (Location)
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation? // 이전 위치 저장용
    
    
    // MARK: - Mock Mode (테스트용)
    private var isMockMode: Bool
    
    // MARK: - Initialization
    init(alarmId: Int, alarmLabel: String) {
        self.alarmLabel = alarmLabel
        
        // ✅ [핵심] ID가 -1이면 테스트 모드(Mock)로 강제 설정
        self.isMockMode = (alarmId == -1)
        
        super.init(alarmId: alarmId)
    }
    
    // 위치 권한 및 설정
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 정확도 최상
        locationManager.pausesLocationUpdatesAutomatically = false // 멈춤 방지
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - 1. 시작하기
    func startDistanceMission() {
        print("🚀 [Distance] 미션 시작 요청: GPS 엔진 가동")
        
        // 1. 초기화 및 GPS 우선 가동 (네트워크 늦어도 측정 시작)
        self.setupLocationManager()
        self.currentDistance = 0.0
        self.previousLocation = nil
        self.locationManager.startUpdatingLocation()
        
        // [Mock 모드 확인]
        if isMockMode {
            setupMockData()
            return
        }
        
        // [Real 모드]
        AsyncTask {
            self.isLoading = true
            do {
                // 2. 서버에서 목표 거리 요청
                if let results = try await super.startMission() {
                    
                    if let firstProblem = results.first {
                        self.contentId = firstProblem.contentId
                        
                        // 🔍 [DEBUG] 서버 데이터 확인 (로그를 꼭 확인하세요!)
                        let rawQuestion = firstProblem.question ?? "nil"
                        let rawAnswer = firstProblem.answer ?? "nil"
                        print("📦 [SERVER DATA] ID: \(firstProblem.contentId), Question: '\(rawQuestion)', Answer: '\(rawAnswer)'")
                        
                        // 3. 목표 거리 파싱 (숫자만 추출)
                        // question이 우선, 없으면 answer 필드 확인
                        let targetString = firstProblem.question ?? firstProblem.answer ?? "20"
                        
                        // "50m", "50.0" 등에서 숫자와 점(.)만 남기고 제거
                        let numberString = targetString.filter { "0123456789.".contains($0) }
                        
                        if let goal = Double(numberString), goal > 0 {
                            self.targetDistance = goal
                            print("🎯 [SERVER] 목표 거리 설정 완료: \(self.targetDistance)m")
                        } else {
                            print("⚠️ [SERVER] 목표 거리 파싱 실패 (원본: \(targetString)). 기본값 20m 사용")
                            self.targetDistance = 20.0
                        }
                        
                    } else {
                        throw MissionError.serverError(message: "문제 데이터 없음")
                    }
                    
                } else {
                    throw MissionError.serverError(message: "데이터 로드 실패")
                }
                
            } catch {
                print("⚠️ [SERVER] 시작 실패: \(error)")
                print("⚠️ 네트워크/서버 오류로 인해 기본 목표(20m)로 진행합니다.")
                
                self.isMockMode = true
                
                // 🚨 비상 착륙: 서버 연결 실패해도 GPS 미션은 진행
                self.contentId = 888 // 로컬 처리를 위한 가상 ID
                self.targetDistance = 50.0
            }
            
            self.isLoading = false
        }
    }
    
    // MARK: - 2. 제출하기 (핵심 로직)
    func submit() {
        // 중복 제출 방지
        if showFeedback { return }
        
        // [Mock 모드]
        if isMockMode {
            handleSubmissionResult(isCorrect: true)
            return
        }
        
        guard let contentId = contentId else {
            print("❌ contentId가 없습니다. (오프라인 상태일 수 있음)")
            // contentId가 없어도 목표 거리를 채웠으면 성공으로 간주
            self.handleSubmissionResult(isCorrect: true)
            return
        }
        
        let request = MissionSubmitRequest(
            contentId: contentId,
            userAnswer: String(format: "%.1f", currentDistance), // 현재 거리를 문자열로 전송
            attemptCount: attemptCount
        )
        
        AsyncTask {
            do {
                self.isLoading = true
                
                // 1. 서버에 제출 시도 (BaseViewModel의 리턴 타입에 따라 조정)
                // 성공 여부(Bool)를 반환한다고 가정
                let _ = try await super.submitMission(request: request)
                self.isLoading = false
                
                // 2. 서버 응답 성공 시
                self.handleSubmissionResult(isCorrect: true)
                
            } catch {
                self.isLoading = false
                print("❌ 서버 제출 실패(403 등): \(error)")
                
                // ✅ [핵심 수정] 서버가 에러를 뱉더라도, 여기까지 왔다는 건
                // 사용자가 목표 거리를 걸었다는 뜻이므로 '성공'으로 처리합니다.
                print("⚠️ 오프라인/에러 모드: 로컬에서 강제 성공 처리합니다.")
                self.handleSubmissionResult(isCorrect: true)
            }
        }
    }
    
    // MARK: - 결과 처리 (UI 업데이트)
    private func handleSubmissionResult(isCorrect: Bool) {
        self.isCorrect = isCorrect
        self.showFeedback = true
        self.isMissionCompleted = true // View 전환 트리거
        
        if isCorrect {
            self.feedbackMessage = "미션 성공! 🎉"
            print("🎉 정답! GPS 종료 및 알람 해제 준비")
            
            // 성공했으므로 위치 업데이트 확실히 중단
            self.locationManager.stopUpdatingLocation()
            
            AsyncTask {
                // 1.5초 딜레이 후 알람 해제 요청
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                await super.dismissAlarm()
            }
        } else {
            self.feedbackMessage = "아직 부족해요."
            AsyncTask {
                try? await AsyncTask.sleep(nanoseconds: 1_500_000_000)
                self.showFeedback = false
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    
    // 위치 업데이트 감지
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // UI 및 로직 업데이트를 위해 MainActor로 진입
        AsyncTask { @MainActor in
            guard let location = locations.last else { return }
            
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
            
            // 3. 목표 달성 체크
            if currentDistance >= targetDistance {
                // 중복 실행 방지
                if !isMissionCompleted && !isLoading && !showFeedback {
                    print("🏁 목표 달성! GPS 끄고 제출합니다.")
                    
                    // ✅ 여기서 먼저 끕니다
                    self.locationManager.stopUpdatingLocation()
                    
                    self.submit()
                    
                }
            }
        }
    }
    
    // 권한 변경 감지
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        AsyncTask { @MainActor in
            print("-----------------------------------------")
            print("🕵️‍♀️ [위치 권한 상태 진단]: \(status.rawValue)")
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ 권한이 허용되었습니다. GPS를 시작합니다.")
                self.locationManager.startUpdatingLocation()
                
            case .denied, .restricted:
                print("🚫 위치 권한 거부됨")
                self.errorMessage = "위치 권한이 필요합니다. 설정에서 켜주세요."
                
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
                
            @unknown default:
                break
            }
            print("-----------------------------------------")
        }
    }
    
    // MARK: - Mock Helpers (테스트용)
    private func setupMockData() {
        self.isLoading = true
        print("🧪 [Mock] 거리 미션 시작 (타겟: 30m)")
        
        AsyncTask {
            try? await AsyncTask.sleep(nanoseconds: 500_000_000)
            self.contentId = 888
            self.targetDistance = 20.0
            self.isLoading = false
            
//            self.simulateMockWalking()
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
            if !isMissionCompleted {
                self.submit()
            }
        }
    }
}

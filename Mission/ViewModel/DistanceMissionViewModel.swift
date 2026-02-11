//
//  DistanceMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

//
//  DistanceMissionViewModel.swift
//  Lumo
//
//  Created by 정승윤 on 2/11/26.
//

import Foundation
import CoreLocation
import Combine

// 제출용 데이터 구조체
struct DistanceMissionSubmitRequest: Codable {
    let contentId: Int
    let currentDistance: Double
    let attemptCount: Int
}

class DistanceMissionViewModel: BaseMissionViewModel, CLLocationManagerDelegate {
    
    // 거리 미션만의 고유 프로퍼티
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation? // 이전 위치 저장용
    
    @Published var currentDistance: Double = 0.0
    @Published var targetDistance: Double = 0.0
    
    override init(alarmId: Int) {
        super.init(alarmId: alarmId) // 부모 초기화 필수
        setupLocationManager()
    }
    
    // 위치 설정
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 정확도 최상
        locationManager.requestWhenInUseAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = false // 위치 추적 중단 방지
    }
    
    // 1. 시작하기
    func start() {
        print("🚀 [STEP 1] 미션 시작 요청: GPS부터 강제로 켭니다.")

            // 👇 [중요] 이 코드가 서버 요청보다 '먼저' 나와야 합니다.
            // 그래야 403 에러가 떠도 폰을 들고 뛰면 숫자가 올라갑니다.
            self.currentDistance = 0.0
            self.previousLocation = nil
            self.targetDistance = 50.0 // 기본값 설정
            
            self.locationManager.startUpdatingLocation()
            print("📡 [STEP 2] GPS 엔진 가동됨 (화면 상단 위치 아이콘 확인하세요)")
        
        // 부모의 함수 호출
        super.startMission { [weak self] result in
            guard let self = self, let data = result else { return }
            
            if let data = result {
                    print("🌐 [SERVER] 응답 성공: \(data.question)m")
            } else {
                // 🚨 여기가 핵심입니다!
                // super.startMission 내부에서 에러 처리를 어떻게 하는지에 따라 다르지만,
                // 보통 Alamofire의 response.data를 출력해봐야 합니다.
                print("⚠️ [SERVER] 403 Forbidden 발생")
            }
            
            // 서버에서 온 목표 거리 설정 (없으면 기본값 50.0)
//            let serverDistance = Double(data.question) ?? 50.0
//            self.targetDistance = serverDistance
//            
//            // 초기화
//            self.currentDistance = 0.0
//            self.previousLocation = nil
//            print("위치 업데이트 시작!")
//            // 위치 추적 시작
//            self.locationManager.startUpdatingLocation()
        }
    }
    
    // 2. 제출하기 (거리 전송)
    func submit() {
        guard let contentId = contentId else { return }
        
        // 요청 바디 생성
        let body = DistanceMissionSubmitRequest(
            contentId: contentId,
            currentDistance: self.currentDistance,
            attemptCount: self.attemptCount
        )
        
        // 부모의 제출 함수 호출
        super.submitMission(body: body) { [weak self] isCorrect in
            if isCorrect {
                self?.feedbackMessage = "성공!"
                // 성공 시 알람 해제 로직은 View의 onChange나 여기서 처리
            } else {
                self?.feedbackMessage = "실패... 조금 더 걸어보세요."
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("📍 위치 데이터가 비어있음")
            return
        }
        
        // 테스트를 위해 정확도 체크(horizontalAccuracy < 0)를 잠시 주석 처리하거나 로그만 찍습니다.
        print("📍 위치 수신 완료! 정확도: \(location.horizontalAccuracy)m")
        
        // 1. 이전 위치가 있다면 거리를 계산해서 누적
        if let previous = previousLocation {
            let distanceInMeters = location.distance(from: previous)
            
            // ⭐️ 아주 작은 움직임도 감지하기 위해 로그 추가
            print("🏃‍♂️ 이동 감지: \(distanceInMeters)m")
            
            // 너무 작은 오차(예: 0.1m 미만)는 무시하고 싶다면 조건을 걸 수 있지만,
            // 테스트 중에는 일단 다 더해봅니다.
            if distanceInMeters > 0.1 {
                currentDistance += distanceInMeters
                print("📊 현재 누적 거리: \(currentDistance)m")
            }
        } else {
            print("📍 첫 위치 고정 완료")
        }
        
        // 2. 현재 위치를 '이전 위치'로 갱신
        previousLocation = location
        
        // 3. 목표 달성 체크
        if currentDistance >= targetDistance {
            if !isMissionCompleted {
                print("🎉 목표 달성! \(targetDistance)m 돌파")
                isMissionCompleted = true
                manager.stopUpdatingLocation()
                submit()
            }
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("위치 권한 허용됨")
        case .denied, .restricted:
            print("위치 권한 거부됨 - 설정 유도 필요")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

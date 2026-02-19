//
//  LocationSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

import SwiftUI
import CoreLocation
import Combine

struct LocationSettingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Environment(\.colorScheme) var scheme
    @Environment(\.scenePhase) var scenePhase
    @Binding var currentPage: Int
    
    @StateObject private var locationManager = LocationAuthManager()
    
    // 권한 거절 상태인지 확인
    @State private var isDenied = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("기기의 위치정보 설정을 허용해주세요.")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(scheme == .dark ? .white : .black)
            
            Spacer() .frame(height: 8)
            
            Text("거리미션을 수행할 때 필요해요!")
                .font(.body)
                .foregroundStyle(scheme == .dark ? Color.gray400 : Color(hex: "7A7F88"))
            
            Spacer()
            
            Image("MissionClap")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // ✅ 이미 거절된 경우에만 설정 버튼 표시
            if isDenied {
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("설정으로 이동해 허용하기")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.bottom, 20)
            } else {
                Spacer().frame(height: 76)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden(true)
        
        // 1. 화면이 나타날 때 (앱 시작 시 바로 이 페이지일 경우)
        .onAppear {
            if currentPage == 3 {
                processLocationPermission()
            }
        }
        
        // 2. 페이지 전환으로 진입했을 때 (Preloading 문제 해결)
        .onChange(of: currentPage) { _, newValue in
            if newValue == 3 {
                processLocationPermission()
            }
        }
        
        // 3. 설정 앱 갔다 왔을 때 상태 업데이트
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                locationManager.checkStatus()
                // 체크 후 상태 반영을 위해 잠시 딜레이
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    updateAuthorizationState()
                }
            }
        }
        
        // 4. 권한 상태가 변경되었을 때 (팝업에서 선택 시)
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            updateAuthorizationState()
        }
    }
    
    // MARK: - 로직 분리
    
    private func processLocationPermission() {
        // 1. 요청 시도 (팝업)
        locationManager.requestLocationPermission()
        
        // 2. 이미 결정된 상태(허용/거절)일 수 있으므로 즉시 상태 확인
        // (팝업이 안 뜬다면 이미 결정된 상태이기 때문)
        updateAuthorizationState()
    }
    
    private func updateAuthorizationState() {
        guard currentPage == 3 else { return }
        
        let status = locationManager.authorizationStatus
        print("📍 현재 위치 권한 상태 확인: \(status.rawValue)")
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            // 이미 허용됨 -> 다음 페이지로
            print("✅ 이미 허용된 상태 -> 다음 페이지 이동")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    currentPage = 4
                }
            }
            
        case .denied, .restricted:
            // 거절됨 -> 설정 버튼 표시
            print("🚫 거절된 상태 -> 버튼 표시")
            withAnimation {
                isDenied = true
            }
            
        case .notDetermined:
            // 아직 결정 안 됨 -> 아무것도 안 함 (팝업 뜰 것임)
            print("⏳ 권한 미결정 -> 팝업 대기")
            isDenied = false
            
        @unknown default:
            break
        }
    }
}

// MARK: - 위치 권한 관리자
class LocationAuthManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        // 초기화 시점의 상태 저장
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        // 아직 결정 안 됐으면 팝업 요청
        if locationManager.authorizationStatus == .notDetermined {
            print("📡 위치 권한 팝업 요청 보냄")
            locationManager.requestWhenInUseAuthorization()
        } else {
            // 이미 결정됐으면 상태만 갱신 (View에서 감지하도록)
            print("📡 이미 권한 결정됨: \(locationManager.authorizationStatus.rawValue)")
            checkStatus()
        }
    }
    
    func checkStatus() {
        // 상태 강제 업데이트 (View의 onChange 트리거용)
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    // Delegate: 권한 변경 감지
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("⚡️ Delegate 감지: \(self.authorizationStatus.rawValue)")
        }
    }
}

#Preview {
    LocationSettingView(currentPage: .constant(3))
        .environment(OnboardingViewModel())
}

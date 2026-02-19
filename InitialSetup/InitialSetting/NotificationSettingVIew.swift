//
//  NotificationSettingView.swift
//  Lumo
//
//  Created by 김승겸 on 1/15/26.
//

import SwiftUI
import UserNotifications

struct NotificationSettingView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Environment(\.colorScheme) var scheme // 다크 모드 감지
    @Environment(\.scenePhase) var scenePhase // 설정 갔다 왔을 때 상태 확인용
    @Binding var currentPage: Int
    
    // 권한 거절 상태인지 확인하는 변수
    @State private var isDenied = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("기기의 알림 설정을 허용해주세요.")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(scheme == .dark ? .white : .black)
            
            Spacer() .frame(height: 8)
            
            Text("알람이 울리려면 꼭 필요해요!")
                .font(.body)
                .foregroundStyle(scheme == .dark ? Color.gray400 : Color(hex: "7A7F88"))
            
            Spacer()
            
            Image("MissionClap")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // ✅ 이미 거절된 경우에만 설정 이동 버튼 표시 (그 외에는 자동 팝업이 뜸)
            if isDenied {
                Button(action: {
                    openAppSettings()
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
        
        // ✅ [수정 1] 화면이 처음 로드될 때 (바로 이 페이지로 시작하는 경우 대응)
        .onAppear {
            if currentPage == 2 {
                requestNotificationPermission()
            }
        }
        
        // ✅ [수정 2] 탭뷰 등에서 화면이 전환되어 이 페이지 번호가 되었을 때 실행 (Preloading 문제 해결)
        .onChange(of: currentPage) { _, newValue in
            if newValue == 2 {
                requestNotificationPermission()
            }
        }
        
        // 설정 앱에서 돌아왔을 때 확인
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkPermissionStatus()
            }
        }
    }
    
    // MARK: - 알림 권한 요청 로직
    private func requestNotificationPermission() {
        _Concurrency.Task {
            // 중복 실행 방지 및 현재 페이지 재확인
            guard currentPage == 2 else { return }
            
            let granted = await AlarmKitManager.shared.requestNotificationAuthorization()
            
            if granted {
                print("✅ 알림 권한 허용됨 (자동)")
                // UI 업데이트는 메인 스레드에서
                DispatchQueue.main.async {
                    withAnimation {
                        currentPage = 3 // 다음 페이지(위치 설정)로 이동
                    }
                }
            } else {
                print("🚫 알림 권한 거절됨 또는 이미 거절 상태")
                checkPermissionStatus()
            }
        }
    }
    
    // 권한 상태 확인
    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            
            DispatchQueue.main.async {
                // 현재 페이지가 2번일 때만 동작하도록 안전장치
                guard currentPage == 2 else { return }
                
                if status == .authorized {
                    withAnimation { currentPage = 3 }
                } else if status == .denied {
                    self.isDenied = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NotificationSettingView(currentPage: .constant(2))
        .environment(OnboardingViewModel())
}

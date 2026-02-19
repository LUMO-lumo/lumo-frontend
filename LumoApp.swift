//
//  LumoApp.swift
//  Lumo
//
//  Created by 김승겸 on 1/2/26.
//

import SwiftUI
import SwiftData
import UserNotifications
import Combine

// ✅ 1. Notification 이름 정의 (다른 파일에 없다면 여기에 포함)
extension Notification.Name {
    static let forceLogout = Notification.Name("ForceLogoutNotification")
}

@main
struct LumoApp: App {
    // UserDefaults 연동
    @AppStorage("userTheme") private var userTheme: String = "System"
    @AppStorage("isOnboardingFinished") var isOnboardingFinished: Bool = false
    
    // 전역 상태 관리 객체 생성
    @StateObject private var appState = AppState()
    @State private var onboardingViewModel = OnboardingViewModel()
    
    // ✅ [추가] 알람 매니저 상태 감지 (알람이 울리는지 확인하기 위해 추가)
    @StateObject private var alarmManager = AlarmKitManager.shared
    
    var body: some Scene {
        WindowGroup {
            // ✅ 2. modelContext 접근을 위해 내부 뷰로 분리
            LumoContentView(
                isOnboardingFinished: $isOnboardingFinished,
                userTheme: userTheme,
                onboardingViewModel: onboardingViewModel
            )
            .environmentObject(appState)
            // ✅ 3. SwiftData 컨테이너 설정 (최상위)
            .modelContainer(for: [UserModel.self, RoutineType.self, RoutineTask.self, TodoEntity.self]) // TodoEntity 추가 확인
        }
    }
}

/// ✅ 4. 실제 콘텐츠 뷰 (Environment 접근 가능)
struct LumoContentView: View {
    @Binding var isOnboardingFinished: Bool
    let userTheme: String
    let onboardingViewModel: OnboardingViewModel
    
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext // ✅ 여기서 접근 가능
    
    // ✅ 알람 매니저 감지
    @StateObject private var alarmManager = AlarmKitManager.shared
    
    // ✅ [NEW] 최상위 레벨에서 브리핑을 담당할 뷰모델
    // 화면에 보이지 않아도 로직을 수행하기 위해 선언합니다.
    @StateObject private var globalHomeViewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            // [Layer 1] 메인 앱 콘텐츠
            Group {
                // appState에 따라 루트 화면 교체
                switch appState.currentRoot {
                case .onboarding:
                    NavigationStack(path: .constant(onboardingViewModel.path)) {
                        OnBoardingView()
                            .navigationDestination(for: OnboardingStep.self) { step in
                                switch step {
                                case .initialSetup:
                                    InitialSetupContainerView()
                                case .introMission:
                                    MissionIntroView()
                                case .missionSelect:
                                    MissionContainerView()
                                case .home:
                                    Color.clear
                                        .onAppear {
                                            isOnboardingFinished = true
                                            withAnimation {
                                                appState.currentRoot = .main
                                            }
                                        }
                                }
                            }
                    }
                    
                case .main:
                    MainView()
                    
                // (아래 case들은 일반적인 네비게이션용 - 오버레이와는 별개로 유지)
                case .mathMission(let alarmId, let label):
                    MathMissionView(alarmId: alarmId, alarmLabel: label)
                    
                case .distanceMission(let alarmId, let label):
                    DistanceMissionView(alarmId: alarmId, alarmLabel: label)
                    
                case .oxMission(let alarmID, let label):
                    OXMissionView(alarmId: alarmID, alarmLabel: label)
                    
                case .typingMission(let alarmId, let label):
                    TypingMissionView(alarmId: alarmId, alarmLabel: label)
                }
            }
            .environment(onboardingViewModel)
            .preferredColorScheme(selectedScheme)
            
            // [Layer 2] 알람 발생 시 최상단 오버레이 (미션 화면)
            if alarmManager.showMissionView {
                AlarmPlayingOverlay()
                    .transition(.opacity)
                    .zIndex(9999) // 무조건 최상단
            }
        }
        // ✅ [NEW] 미션 완료 신호 감지 (앱 어디에 있든 작동)
        .onChange(of: alarmManager.shouldPlayBriefing) { oldValue, newValue in
            if newValue {
                print("📣 [Global] 미션 완료 감지 -> 브리핑 시작")
                
                // 1. (선택) 미션이 끝나면 홈 화면으로 이동시킬 것인가?
                // 만약 사용자가 설정 탭에 있었더라도 홈으로 보내고 싶다면 아래 코드 활성화
                if appState.currentRoot != .main {
                     appState.currentRoot = .main
                }
                
                // 2. 브리핑 실행 (오버레이가 닫히는 애니메이션 등을 고려해 약간 딜레이)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    globalHomeViewModel.checkAndPlayBriefing()
                }
            }
        }
        // ✅ 6. 온보딩 상태 변경 감지
        .onChange(of: isOnboardingFinished) { _, newValue in
            if newValue && appState.currentRoot == .onboarding {
                appState.currentRoot = .main
            } else if !newValue {
                appState.currentRoot = .onboarding
            }
        }
        
        // ✅ 7. [핵심] 강제 로그아웃 신호 감지 및 처리
        .onReceive(NotificationCenter.default.publisher(for: .forceLogout)) { _ in
            performForceLogout()
        }
    }
    
    /// 테마 설정
    var selectedScheme: ColorScheme? {
        switch userTheme {
        case "LIHGT": return .light
        case "DARK": return .dark
        default: return nil
        }
    }
    
    /// ✅ 8. 강제 로그아웃 실행 로직
    private func performForceLogout() {
        print("🧹 [LumoApp] 강제 로그아웃 신호 수신 -> 데이터 삭제 시작")
        
        // 1. 키체인 토큰 삭제
        try? KeychainManager.standard.deleteSession(for: "userSession")
        
        // 2. SwiftData 유저 정보 삭제 (배열 전체 삭제)
        do {
            try modelContext.delete(model: UserModel.self)
            print("✅ 유저 데이터 삭제 완료")
        } catch {
            print("❌ 유저 데이터 삭제 실패: \(error)")
        }
        
        // 3. (선택사항) 필요하다면 상태 리셋 또는 알림 표시
        // 뷰 계층구조(MainView -> LoginSectionView)가 자동으로 갱신되어 "로그인이 필요해요" 상태가 됩니다.
    }
}

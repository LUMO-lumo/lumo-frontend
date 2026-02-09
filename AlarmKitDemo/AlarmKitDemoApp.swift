import SwiftUI
import AlarmKit

// MARK: - 앱의 진입점 (Entry Point)
// @main 속성은 이 구조체가 앱의 시작점임을 나타냅니다.
@main
struct AlarmKitDemoApp: App {
    // MARK: - 전역 상태 관리
    // 앱 전체에서 공유될 알람 매니저를 초기화합니다.
    // @StateObject는 뷰의 수명 주기와 무관하게 객체를 유지합니다.
    @StateObject private var alarmSoundManager = AlarmSoundManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // 하위 뷰들이 alarmSoundManager에 접근할 수 있도록 환경 객체로 주입합니다.
                .environmentObject(alarmSoundManager)
                // 앱이 시작되자마자 비동기적으로 권한을 요청합니다.
                .task {
                    //앱을 시작하자마자 권한 요청 팝업
                    await requestAlarmAuthorization()
                }
        }
    }
    
    // MARK: - AlarmKit 권한 요청 로직
    // iOS 시스템 알람 기능에 접근하기 위해 사용자 허용이 필요합니다.
    // 팝업으로 처음 알람 권한을 요청하는 부분 추후에 다른 파트에서 나오게 만들 수 있음
    
    
    
    private func requestAlarmAuthorization() async {
        do {
            // AlarmManager 싱글톤을 통해 권한 요청
            let state = try await AlarmManager.shared.requestAuthorization()
            switch state {
            case .authorized:
                print("✅ AlarmKit 권한 승인됨: 이제 시스템 알람 기능을 사용할 수 있습니다.")
            case .denied:
                print("❌ AlarmKit 권한 거부됨: 설정에서 권한을 켜야 합니다.")
            case .notDetermined:
                print("⏳ AlarmKit 권한 미결정: 아직 사용자가 선택하지 않았습니다.")
            @unknown default:
                break
            }
        } catch {
            print("권한 요청 실패: \(error.localizedDescription)")
        }
    }
}

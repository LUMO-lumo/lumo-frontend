import SwiftUI
import AlarmKit

// MARK: - 메인 컨테이너 뷰
// 앱의 전체적인 화면 흐름과 오버레이를 관리합니다.
struct ContentView: View {
    @StateObject private var alarmManager = AlarmSoundManager.shared
    @State private var showingAddAlarm = false // 알람 추가 시트 표시 여부
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. 메인 컨텐츠 영역
                VStack {
                    // 권한이 없으면 권한 요청 화면, 있으면 알람 목록 화면 표시
                    if !alarmManager.isAuthorized {
                        AuthorizationRequestView()
                    } else {
                        AlarmListView()
                    }
                }
                
                // 2. 알람 발생 시 오버레이 (ZStack 최상단)
                // isAlarmPlaying이 true가 되면 화면 전체를 덮는 알람 화면이 뜹니다.
                if alarmManager.isAlarmPlaying {
                    AlarmPlayingOverlay()
                }
            }
            .navigationTitle("⏰ AlarmKit Demo")
            .toolbar {
                // 우측 상단 '+' 버튼 (알람 추가)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    // 권한이 없으면 버튼 비활성화
                    .disabled(!alarmManager.isAuthorized)
                }
            }
            // 알람 추가 모달 시트
            .sheet(isPresented: $showingAddAlarm) {
                AlarmDetailView(alarm: AlarmModel(), isNewAlarm: true)
            }
        }
    }
}

// MARK: - 알람 재생 중 오버레이 뷰
// 알람이 울릴 때 사용자가 '알람 중지'를 누를 수 있도록 하는 전체 화면 UI
struct AlarmPlayingOverlay: View {
    @StateObject private var alarmManager = AlarmSoundManager.shared
    
    var body: some View {
        ZStack {
            // 검은 배경 (불투명도 80%)
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 진동하는 알람 아이콘 효과
                Image(systemName: "alarm.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .symbolEffect(.pulse) // iOS 17+ 애니메이션 효과
                
                Text("알람이 울리고 있습니다!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // 알람 중지 버튼
                Button {
                    alarmManager.stopAlarmSound() // 소리 끄기 및 오버레이 닫기
                } label: {
                    Text("알람 중지")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.red)
                        .cornerRadius(30)
                }
            }
        }
    }
}

// MARK: - 권한 요청 뷰
// AlarmKit 권한이 아직 없을 때 보여주는 안내 화면
struct AuthorizationRequestView: View {
    @StateObject private var alarmManager = AlarmSoundManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("알람 권한이 필요합니다")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("알람 기능을 사용하려면\n알람 권한을 허용해 주세요.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("권한 요청") {
                Task {
                    await alarmManager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

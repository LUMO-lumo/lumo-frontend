import SwiftUI

// MARK: - 사운드 선택 뷰
// 사용자가 알람음을 선택하고 미리 들어볼 수 있는 리스트 화면입니다.
struct SoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var alarmManager = AlarmSoundManager.shared
    @Binding var selectedSound: String // 부모 뷰(DetailView)의 선택값과 바인딩
    
    @State private var currentlyPlaying: String? // 현재 미리듣기 중인 사운드명
    
    var body: some View {
        List {
            // AlarmSoundManager에 정의된 가용 사운드 목록 순회
            ForEach(alarmManager.availableSounds, id: \.self) { sound in
                HStack {
                    // 1. 선택 상태 표시 (체크마크)
                    // 선택되는 논리 작동
                    Image(systemName: selectedSound == sound ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedSound == sound ? .blue : .secondary)
                    
                    // 2. 사운드 이름 표시 (포맷팅 적용)
                    Text(formatSoundName(sound))
                    
                    Spacer()
                    
                    // 3. 미리듣기 재생/정지 버튼
                    Button {
                        togglePreview(sound)
                    } label: {
                        Image(systemName: currentlyPlaying == sound ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain) // 리스트 행 터치와 간섭 방지
                }
                .contentShape(Rectangle())
                // 행을 탭하면 해당 사운드 선택
                .onTapGesture {
                    selectedSound = sound
                }
            }
        }
        .navigationTitle("알람 사운드")
        .navigationBarTitleDisplayMode(.inline)
        // 화면을 나갈 때 미리듣기 중지
        .onDisappear {
            alarmManager.stopPreview()
        }
    }
    
    // 파일명을 보기 좋은 이름으로 변환 (언더바 제거 등)
    private func formatSoundName(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    // 미리듣기 토글 로직
    private func togglePreview(_ sound: String) {
        if currentlyPlaying == sound {
            // 이미 재생 중이면 정지
            alarmManager.stopPreview()
            currentlyPlaying = nil
        } else {
            // 새로운 사운드 재생
            alarmManager.previewSound(named: sound)
            currentlyPlaying = sound
            
            // 5초 후 자동 정지 (미리듣기이므로)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if currentlyPlaying == sound {
                    alarmManager.stopPreview()
                    currentlyPlaying = nil
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SoundPickerView(selectedSound: .constant("alarm_default"))
    }
}

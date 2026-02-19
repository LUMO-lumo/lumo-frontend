import SwiftUI
import Foundation
import SwiftData
import PhotosUI
import Combine
import Moya

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var showToDoSheet = false
    @State private var navigateToDetail = false
    @StateObject private var alarmViewModel = AlarmViewModel()
    
    // ✅ AlarmKitManager는 LumoApp에서 전역으로 처리하므로 여기서 감지할 필요 없음
    // @ObservedObject private var alarmKitManager = AlarmKitManager.shared (삭제 또는 주석)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LUMO")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color(hex: "F55641"))
                        
                        Text("단순한 알람이 아닌,\n당신을 행동으로 이끄는 AI 미션 알람 서비스")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    
                    quoteCardSection
                    todoPreviewSection
                    missionStatSection
                    
                    Spacer().frame(height: 40)
                    // MARK: - 미션 테스트 섹션 (Mock Data 사용)
                                        // ⚠️ 각 ViewModel에서 alarmId가 -1일 경우 Mock 모드로 동작하도록 설정 필요
                                        HStack(spacing: 10) {
                                            // 1. 수학 미션 테스트
                                            Button {
                                                print("🧪 수학 미션 Mock 테스트 시작")
                                                withAnimation {
                                                    // ID -1은 테스트용 약속된 ID입니다.
                                                    appState.currentRoot = .mathMission(alarmId: -1, label: "수학 테스트")
                                                }
                                            } label: {
                                                Text("수학")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.orange)
                                                    .cornerRadius(12)
                                            }
                                            
                                            // 2. 거리 미션 테스트
                                            Button {
                                                print("🧪 거리 미션 Mock 테스트 시작")
                                                withAnimation {
                                                    appState.currentRoot = .distanceMission(alarmId: -1, label: "거리 테스트")
                                                }
                                            } label: {
                                                Text("거리")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.green)
                                                    .cornerRadius(12)
                                            }
                                            
                                            // 3. OX 미션 테스트
                                            Button {
                                                print("🧪 OX 미션 Mock 테스트 시작")
                                                withAnimation {
                                                    appState.currentRoot = .oxMission(alarmId: -1, label: "OX 테스트")
                                                }
                                            } label: {
                                                Text("OX")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.blue)
                                                    .cornerRadius(12)
                                            }
                                            
                                            // 4. 따라쓰기 미션 테스트
                                            Button {
                                                print("🧪 따라쓰기 미션 Mock 테스트 시작")
                                                withAnimation {
                                                    appState.currentRoot = .typingMission(alarmId: -1, label: "쓰기 테스트")
                                                }
                                            } label: {
                                                Text("쓰기")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.purple)
                                                    .cornerRadius(12)
                                            }
                                        }
                                        .padding(.top, 20)
                    
                    Spacer().frame(height: 40)
                    // MARK: - 미션 테스트 섹션
                    HStack(spacing: 10) {
                        Button {
                            guard let targetAlarm = alarmViewModel.alarms.last,
                                  let serverId = targetAlarm.serverId else { return }
                            withAnimation {
                                appState.currentRoot = .mathMission(alarmId: serverId, label: targetAlarm.label)
                            }
                        } label: {
                            Text("수학 미션")
                                .font(.caption).bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            guard let targetAlarm = alarmViewModel.alarms.last,
                                  let serverId = targetAlarm.serverId else { return }
                            withAnimation {
                                appState.currentRoot = .distanceMission(alarmId: serverId, label: targetAlarm.label)
                            }
                        } label: {
                            Text("거리 미션")
                                .font(.caption).bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
            }
            .toolbar(.hidden)
            .onAppear {
                // 1. 데이터 로드 (화면 진입 시 갱신용)
                viewModel.loadTasksForSpecificDate(date: Date())
                
                // ❌ [삭제] 여기서 브리핑 체크를 하지 않습니다.
                // LumoApp.swift에서 전역으로 처리하므로 중복 실행을 막기 위해 제거합니다.
                // viewModel.checkAndPlayBriefing()
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                TodoSettingView(viewModel: viewModel)
            }
            .sheet(isPresented: $showToDoSheet) {
                ToDoSheetView(viewModel: viewModel, showSheet: $showToDoSheet, showDetail: $navigateToDetail)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - 하위 컴포넌트
private extension HomeView {
    var quoteCardSection: some View {
        ZStack {
            Image("HomePartImage")
                .resizable()
                .frame(height: 180)
            Color.black.opacity(0.3)
            VStack(spacing: 5) {
                Text("오늘의 한마디")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                
                Text(viewModel.dailyQuote)
                    .font(.headline)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    var todoPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("오늘의 할 일")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { navigateToDetail = true }) {
                    Text("자세히 보기 >")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "BBC0C7"))
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.todayTasksList.isEmpty {
                    Text("오늘 등록된 할 일이 없습니다.")
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(Array(viewModel.previewTasks.enumerated()), id: \.element.id) { index, task in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(task.isCompleted ? Color(hex: "F55641") : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                Text(task.title)
                                    .font(.body)
                                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                    .strikethrough(task.isCompleted)
                            }
                            .padding(.horizontal, 4)
                            if index < viewModel.previewTasks.count - 1 {
                                Divider()
                                    .background(Color.secondary.opacity(0.3))
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .onTapGesture {
                showToDoSheet = true
            }
        }
    }
    
    var missionStatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("최근 미션 성공")
                .font(.title3)
                .fontWeight(.bold)
            HStack(spacing: 12) {
                StatCard(number: "\(viewModel.missionStat.consecutiveDays)일", label: "연속성공")
                StatCard(number: viewModel.missionStat.ratePercentage, label: "이번달 달성률")
            }
        }
    }
}

struct StatCard: View {
    let number: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct ToDoSheetView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var showSheet: Bool
    @Binding var showDetail: Bool
    @State private var editingTaskId: UUID?
    let themeColor = Color(hex: "E86457")
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("전체 할 일")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("자세히 보기 >") {
                    showSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showDetail = true }
                }
                .font(.subheadline)
                .foregroundStyle(Color(hex: "BBC0C7"))
                .padding(.top, 16)
            }
            .padding([.top, .horizontal], 24)
            .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach($viewModel.todayTasksList) { $task in
                        SheetTaskRow(task: $task, themeColor: themeColor, isEditing: editingTaskId == task.id,
                                     startEditing: { editingTaskId = task.id },
                                     finishEditing: { editingTaskId = nil },
                                     deleteAction: { viewModel.deleteTask(id: task.id) })
                    }
                }.padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct SheetTaskRow: View {
    @Binding var task: Task
    let themeColor: Color
    let isEditing: Bool
    let startEditing: () -> Void
    let finishEditing: () -> Void
    let deleteAction: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if isEditing {
                    TextField("수정", text: $task.title)
                        .focused($isFocused)
                        .onSubmit { finishEditing() }
                } else {
                    Text(task.title)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Button(action: { isEditing ? finishEditing() : startEditing() }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                        .foregroundStyle(themeColor)
                }
                Button(action: deleteAction) { Image(systemName: "trash")
                    .foregroundStyle(themeColor) }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            Divider()
                .background(Color.gray.opacity(0.3))
        }.onChange(of: isEditing) { _, newValue in if newValue { isFocused = true } }
    }
}

// MARK: - 프리뷰
#Preview {
    HomeView()
}

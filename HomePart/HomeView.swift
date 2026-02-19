import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var alarmViewModel = AlarmViewModel()
    
    @State private var showToDoSheet = false
    @State private var navigateToDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    quoteCardSection
                    
                    todoPreviewSection
                    
                    missionStatSection
                }
                .padding(.horizontal, 24)
            }
            .toolbar(.hidden)
            .onAppear {
                // 데이터 로드 (현재 날짜 기준)
                viewModel.loadTasksForSpecificDate(date: Date())
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

// MARK: - 하위 섹션 컴포넌트
private extension HomeView {
    
    /// 상단 브랜드 헤더
    var headerSection: some View {
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
    }
    
    /// 오늘의 한마디 카드
    var quoteCardSection: some View {
        ZStack {
            Image("HomePartImage")
                .resizable()
                .scaledToFill()
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
                    .padding(.horizontal, 20)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// 오늘의 할 일 미리보기 섹션
    var todoPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.todayTasksList.isEmpty {
                    Text("오늘 등록된 할 일이 없습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                } else {
                    ForEach(Array(viewModel.previewTasks.enumerated()), id: \.element.id) { index, task in
                        taskPreviewRow(task: task, isLast: index == viewModel.previewTasks.count - 1)
                    }
                }
            }
            .padding(20)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .onTapGesture { showToDoSheet = true }
        }
    }
    
    /// 할 일 목록의 개별 행
    @ViewBuilder
    private func taskPreviewRow(task: Task, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(task.isCompleted ? Color(hex: "F55641") : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
            }
            .padding(.vertical, 4)
            
            if !isLast {
                Divider()
                    .background(Color.secondary.opacity(0.2))
            }
        }
    }
    
    /// 최근 미션 성공 통계 섹션
    var missionStatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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

// MARK: - Supporting Views

struct StatCard: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

/// 하단 시트에서 보여주는 할 일 목록 뷰
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showDetail = true
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color(hex: "BBC0C7"))
            }
            .padding([.top, .horizontal], 24)
            .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach($viewModel.todayTasksList) { $task in
                        SheetTaskRow(
                            task: $task,
                            themeColor: themeColor,
                            isEditing: editingTaskId == task.id,
                            startEditing: { editingTaskId = task.id },
                            finishEditing: { editingTaskId = nil },
                            deleteAction: { viewModel.deleteTask(id: task.id) }
                        )
                    }
                }
                .padding(.horizontal, 24)
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
            HStack(spacing: 12) {
                if isEditing {
                    TextField("수정", text: $task.title)
                        .focused($isFocused)
                        .onSubmit { finishEditing() }
                } else {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: { isEditing ? finishEditing() : startEditing() }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                        .foregroundStyle(themeColor)
                }
                
                Button(action: deleteAction) {
                    Image(systemName: "trash")
                        .foregroundStyle(themeColor)
                }
            }
            .padding(.vertical, 16)
            
            Divider()
        }
        .onChange(of: isEditing) { _, newValue in
            if newValue { isFocused = true }
        }
    }
}

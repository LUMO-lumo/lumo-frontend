import SwiftUI
import Foundation
import SwiftData
import PhotosUI
import Combine
import Moya


struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showToDoSheet = false
    @State private var navigateToDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 1. 헤더 (요청하신 대로 직접 텍스트로 수정)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LUMO")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color(hex: "F55641"))
                        
                        // [수정] 뷰모델 참조 대신 직접 텍스트 입력
                        Text("단순한 알람이 아닌,\n당신을 행동으로 이끄는 AI 미션 알람 서비스")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    
                    quoteCardSection
                    todoPreviewSection
                    missionStatSection
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
            .toolbar(.hidden)
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
                
                // 오늘의 명언은 뷰모델의 데이터를 유지하여 동적으로 작동하게 합니다.
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
                NavigationLink(destination: TodoSettingView(viewModel: viewModel)) {
                    Text("자세히 보기 >")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "BBC0C7"))
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.tasks.isEmpty {
                    Text("등록된 할 일이 없습니다.")
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(Array(viewModel.previewTasks.enumerated()), id: \.element.id) { index, task in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(task.title)
                                .font(.body)
                                .foregroundStyle(.black.opacity(0.8))
                                .padding(.horizontal, 4)
                            if index < viewModel.previewTasks.count - 1 {
                                Divider()
                                .background(Color.black.opacity(0.1)) }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(hex: "F2F4F7"))
            .cornerRadius(16)
            .onTapGesture {
                showToDoSheet = true }
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
                .foregroundStyle(.black)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "F2F4F7"))
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
                Text("전체 할 일").font(.title2).fontWeight(.bold)
                Spacer()
                Button("자세히 보기 >") {
                    showSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showDetail = true }
                }
                .font(.subheadline)
                .foregroundStyle(Color(hex: "BBC0C7"))
            }
            .padding([.top, .horizontal], 24)
            .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach($viewModel.tasks) { $task in
                        SheetTaskRow(task: $task, themeColor: themeColor, isEditing: editingTaskId == task.id,
                                     startEditing: { editingTaskId = task.id },
                                     finishEditing: { editingTaskId = nil },
                                     deleteAction: { viewModel.deleteTask(id: task.id) })
                    }
                }.padding(.horizontal)
            }
        }
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
                        .foregroundStyle(.black)
                }
                Spacer()
                Button(action: { isEditing ? finishEditing() : startEditing() }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                        .foregroundStyle(themeColor)
                }
                Button(action: deleteAction) { Image(systemName: "trash").foregroundStyle(themeColor) }
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

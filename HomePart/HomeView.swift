import SwiftUI
import Foundation
import SwiftData
import PhotosUI
import Combine
import Moya

// MARK: - 홈 화면 뷰
struct HomeView: View {
    // 사용자님께서 지정하신 원래 이름 'HomeViewModel'을 그대로 유지합니다.
    @StateObject private var viewModel = HomeViewModel()
    @State private var showToDoSheet = false
    @State private var navigateToDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. 상단 헤더
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LUMO")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color(hex: "F55641"))
                        
                        Text("단순한 알람이 아닌,\n당신을 행동으로 이끄는 AI 미션 알람 서비스")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    
                    // 2. 명언 카드
                    quoteCardSection
                    
                    // 3. 오늘의 할 일 카드
                    todoPreviewSection
                    
                    // 4. 최근 미션 성공
                    missionStatSection
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            }
            .toolbar(.hidden)
            .navigationDestination(isPresented: $navigateToDetail) {
                // TodoSettingView로 이동 시 기존 viewModel 전달
                TodoSettingView(viewModel: viewModel)
            }
            .sheet(isPresented: $showToDoSheet) {
                ToDoSheetView(
                    viewModel: viewModel,
                    showSheet: $showToDoSheet,
                    showDetail: $navigateToDetail
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - HomeView 내부 컴포넌트
private extension HomeView {
    var quoteCardSection: some View {
        ZStack {
            Image("HomePartImage")
                .resizable()
                .frame(height: 180)
                .clipped()
            
            Color.black.opacity(0.3)
            
            VStack(spacing: 5) {
                Text("오늘의 한마디")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                
                Text("당신의 영향력의 한계는\n상상력입니다!")
                    .font(.headline)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    // Task 모호성 해결을 위해 ForEach 내부에서도 안전하게 처리
                    ForEach(Array(viewModel.previewTasks.enumerated()), id: \.element.id) { index, task in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(task.title)
                                .font(.body)
                                .foregroundStyle(.black.opacity(0.8))
                                .padding(.horizontal, 4)
                            
                            if index < viewModel.previewTasks.count - 1 {
                                Divider()
                                    .background(Color.black.opacity(0.1))
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(hex: "F2F4F7"))
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

// MARK: - 최근 미션 성공 카드 뷰
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

// MARK: - 할 일 목록 시트 뷰
struct ToDoSheetView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var showSheet: Bool
    @Binding var showDetail: Bool
    
    @State private var editingTaskId: UUID?
    
    let themeColor = Color(hex: "E86457")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("전체 할 일")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showDetail = true
                    }
                }) {
                    Text("자세히 보기 >")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "BBC0C7"))
                }
            }
            .padding(.top, 40)
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach($viewModel.tasks) { $task in
                        SheetTaskRow(
                            task: $task,
                            themeColor: themeColor,
                            isEditing: editingTaskId == task.id,
                            startEditing: {
                                editingTaskId = task.id
                            },
                            finishEditing: { editingTaskId = nil },
                            deleteAction: {
                                if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                                    viewModel.deleteTask(at: IndexSet([index]))
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

// MARK: - 시트용 할 일 Row
struct SheetTaskRow: View {
    // Swift 내장 Task와의 충돌을 피하기 위해 프로젝트 모듈명을 명시적으로 지정하여 원래 이름을 유지합니다.
    @Binding var task: LUMO_MainDev.Task
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
                    TextField("할 일 입력", text: $task.title)
                        .font(.body)
                        .foregroundStyle(.black)
                        .focused($isFocused)
                        .onSubmit { finishEditing() }
                } else {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                Button(action: {
                    if isEditing { finishEditing() } else { startEditing() }
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                        .font(.system(size: 18))
                        .foregroundStyle(themeColor)
                }
                .padding(.trailing, 8)
                
                Button(action: deleteAction) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundStyle(themeColor)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .onChange(of: isEditing) { oldValue, newValue in
            if newValue { isFocused = true }
        }
    }
}

// MARK: - 프리뷰
#Preview {
    HomeView()
}

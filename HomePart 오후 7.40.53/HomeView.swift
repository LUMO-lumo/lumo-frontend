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
                
                // 1. 상단 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text("LUMO")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    
                    Text("단순한 알람이 아닌,\n당신을 행동으로 이끄는 AI 미션 알람 서비스")
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineSpacing(4)
                }
                .padding(.top, 10)
                
                // 2. 명언 카드
                ZStack {
                    Image("HomePartImage") // Assets 이미지 확인 필요
                        .resizable()
                        .frame(height: 180)
                        .clipped()
                    
                    Color.black.opacity(0.3)
                    
                    VStack(spacing: 5) {
                        Text("오늘의 한마디")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("당신의 영향력의 한계는\n상상력입니다!")
                            .font(.headline)
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 3. 오늘의 할 일 (수정된 부분)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("오늘의 할 일")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: DetailPageView()) {
                            Text("자세히 보기 >")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    
                    // 기존 버튼 대신 리스트 미리보기(3개) 표시
                    VStack(alignment: .leading, spacing: 16) {
                        if dummyTasks.isEmpty {
                            Text("등록된 할 일이 없습니다.")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            // 상위 3개만 표시
                            ForEach(Array(dummyTasks.prefix(3).enumerated()), id: \.offset) { index, task in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(task)
                                        .font(.body)
                                        .foregroundColor(.black.opacity(0.8))
                                        .padding(.horizontal, 4)
                                    
                                    // 마지막 아이템이 아니면 구분선 추가 (선택사항, 디자인에 따라 제거 가능)
                                    if index < 2 && index < dummyTasks.count - 1 {
                                        Divider()
                                            .background(Color.black.opacity(0.1))
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background((Color(hex: "F2F4F7")))
                    .cornerRadius(16)
                    .onTapGesture {
                        // 탭하면 전체 리스트 시트 열기
                        showToDoSheet = true
                    }
                }
                
                // 4. 최근 미션 성공
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("최근 미션 성공")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("자세히 보기 >")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    // 나중에 평균값을 저장하는 부분(더미 데이터)
                    HStack(spacing: 12) {
                        StatCard(number: "5일", label: "연속성공")
                        StatCard(number: "94%", label: "이번달 달성률")
                    }
                }
                
                Spacer().frame(height: 40) // 탭바에 가려지지 않도록 하단 여백 추가
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
        }
        .toolbar(.hidden)
        .sheet(isPresented: $showToDoSheet) {
            // 전체 데이터를 전달
            ToDoSheetView(tasks: dummyTasks)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
                    ForEach($viewModel.tasks) { $task in
                        SheetTaskRow(task: $task, themeColor: themeColor, isEditing: editingTaskId == task.id,
                                     startEditing: { editingTaskId = task.id },
                                     finishEditing: { editingTaskId = nil },
                                     deleteAction: { viewModel.deleteTask(id: task.id) })
                    }
                }.padding(.horizontal)
            }
        }
        .background(.white)
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

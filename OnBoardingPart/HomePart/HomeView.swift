import SwiftUI
import Foundation
import SwiftData
import PhotosUI
import Combine
import Moya

// MARK: - 홈 화면 뷰
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel() // ViewModel 연결
    @State private var showToDoSheet = false
    @State private var navigateToDetail = false // 상세 페이지 이동 제어 변수
    
    // 기존 dummyTasks 제거 (ViewModel 사용)
    
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
                    ZStack {
                        Image("HomePartImage") // Assets 이미지 확인 필요
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
                    
                    // 3. 오늘의 할 일
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("오늘의 할 일")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // [수정] TodoSettingView에 viewModel 전달
                            NavigationLink(destination: TodoSettingView(viewModel: viewModel)) {
                                Text("자세히 보기 >")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "BBC0C7"))
                            }
                        }
                        
                        // 기존 버튼 대신 리스트 미리보기(3개) 표시
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.tasks.isEmpty {
                                Text("등록된 할 일이 없습니다.")
                                    .foregroundStyle(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                // 상위 3개만 표시 (ViewModel 데이터 사용)
                                ForEach(Array(viewModel.previewTasks.enumerated()), id: \.element.id) { index, task in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(task.title)
                                            .font(.body)
                                            .foregroundStyle(.black.opacity(0.8))
                                            .padding(.horizontal, 4)
                                        
                                        // 마지막 아이템이 아니면 구분선 추가
                                        if index < 2 && index < viewModel.previewTasks.count - 1 {
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
                        }
                        // 통계 카드
                        HStack(spacing: 12) {
                            StatCard(number: "\(viewModel.missionStat.consecutiveDays)일", label: "연속성공")
                            StatCard(number: viewModel.missionStat.ratePercentage, label: "이번달 달성률")
                        }
                    }
                    
                    Spacer().frame(height: 40) // 탭바에 가려지지 않도록 하단 여백 추가
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            }
            .toolbar(.hidden)
            // [수정] TodoSettingView에 viewModel 전달
            .navigationDestination(isPresented: $navigateToDetail) {
                TodoSettingView(viewModel: viewModel)
            }
            .sheet(isPresented: $showToDoSheet) {
                // 시트와 상세 이동 상태를 바인딩으로 전달
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

// MARK: - 최근 미션 성공 뷰
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

// MARK: - 시트뷰
struct ToDoSheetView: View {
    @ObservedObject var viewModel: HomeViewModel // 데이터 소스 변경
    @Binding var showSheet: Bool // 시트 닫기용
    @Binding var showDetail: Bool // 부모 뷰 이동 트리거용
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("전체 할 일")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showSheet = false // 시트 닫기
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
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.tasks) { task in
                        VStack(spacing: 0) {
                            HStack {
                                Text(task.title)
                                    .font(.body)
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            
                            Divider()
                                .background(Color.black.opacity(0.1))
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

// MARK: - 프리뷰
#Preview {
    HomeView()
}

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
    @State private var navigateToDetail = false // [추가] 상세 페이지 이동 제어 변수
    
    // 기존 dummyTasks 제거 (ViewModel 사용)
    
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
                            
                            // 홈 화면에서의 바로가기 링크
                            NavigationLink(destination: DetailPageView()) {
                                Text("자세히 보기 >")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                        
                        // 기존 버튼 대신 리스트 미리보기(3개) 표시
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.tasks.isEmpty {
                                Text("등록된 할 일이 없습니다.")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                // 상위 3개만 표시 (ViewModel 데이터 사용)
                                ForEach(Array(viewModel.previewTasks.enumerated()), id: \.element.id) { index, task in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(task.title)
                                            .font(.body)
                                            .foregroundColor(.black.opacity(0.8))
                                            .padding(.horizontal, 4)
                                        
                                        // 마지막 아이템이 아니면 구분선 추가 (선택사항, 디자인에 따라 제거 가능)
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
                        // 나중에 평균값을 저장하는 부분(더미 데이터)
                        // 추후에 성공한 데이터를 가지고 평균과 퍼센트 계산을 해서 표시하는 방식으로 구현
                        HStack(spacing: 12) {
                            // ViewModel 데이터 연결 (디자인 유지)
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
            // [추가] 시트에서 "자세히 보기"를 눌렀을 때 작동하는 네비게이션 트리거
            .navigationDestination(isPresented: $navigateToDetail) {
                DetailPageView()
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
                .foregroundColor(.black)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "F2F4F7"))
        .cornerRadius(16)
    }
}

// MARK: - 나중에 날짜 연결하는 페이지로 이용하게 만드는 페이지
struct DetailPageView: View {
    // [추가] 뒤로가기 버튼 커스텀을 위한 환경 변수 (선택사항)
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("날짜 정하는 페이지")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("더 자세한 내용이 여기에 표시됩니다.")
                .foregroundColor(.gray)
                .padding()
        }
        // 기본 네비게이션 바 설정 (오른쪽 사진처럼 깔끔하게 보이도록)
        .navigationBarBackButtonHidden(false)
    }
}

// MARK: - 시트뷰 (수정된 부분)
struct ToDoSheetView: View {
    @ObservedObject var viewModel: HomeViewModel // 데이터 소스 변경
    @Binding var showSheet: Bool // [추가] 시트 닫기용
    @Binding var showDetail: Bool // [추가] 부모 뷰 이동 트리거용
    
    var body: some View {
        // [수정] NavigationStack 제거 (중첩 네비게이션 방지)
        VStack(alignment: .leading) {
            // HStack + Spacer로 양쪽 정렬
            HStack {
                Text("전체 할 일")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer() // 이 친구가 텍스트와 링크 사이를 벌려줍니다.
                
                // [수정] NavigationLink -> Button으로 변경
                // 시트를 닫고 -> 부모 뷰에서 페이지 이동을 실행합니다.
                Button(action: {
                    showSheet = false // 시트 닫기
                    // 시트가 닫히는 애니메이션과 겹치지 않게 약간의 딜레이를 줄 수도 있지만,
                    // SwiftUI 최신 버전에서는 바로 실행해도 자연스럽게 연결됩니다.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showDetail = true
                    }
                }) {
                    Text("자세히 보기 >")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.top, 40)
            
            ScrollView {
                // [수정] 리스트 아이템과 구분선 추가
                VStack(spacing: 0) { // spacing을 0으로 주어 Divider 간격 제어
                    ForEach(viewModel.tasks) { task in
                        VStack(spacing: 0) {
                            HStack {
                                Text(task.title)
                                    .font(.body)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding(.vertical, 16) // 리스트 아이템의 위아래 여백을 넉넉하게 줍니다
                            
                            // 구분선 (밑줄) 추가
                            Divider()
                                .background(Color.black.opacity(0.1)) // 연한 회색 줄
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

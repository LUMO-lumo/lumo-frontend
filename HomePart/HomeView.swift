import SwiftUI
import Foundation
import SwiftData
import PhotosUI

// MARK: - 홈 화면 뷰
struct HomeView: View {
    @State private var showToDoSheet = false
    let corallightGray = Color(hex: "F2F4F7")
    
    // 더미 데이터 (나중에 ViewModel이나 SwiftData로 교체 가능)
    // 이미지에 있는 내용과 추가 항목을 포함하여 3개 이상으로 설정
    let dummyTasks = [
        "일반쓰레기 버리기",
        "과제 제출하기",
        "공복 유산소하기",
        "일기 쓰기",
        "영양제 챙겨먹기"
    ]
    
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
    var body: some View {
        VStack {
            Text("날짜 정하는 페이지")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("더 자세한 내용이 여기에 표시됩니다.")
                .foregroundColor(.gray)
                .padding()
        }
    }
}

// MARK: - 시트뷰 (수정된 부분)
struct ToDoSheetView: View {
    // HomeView에서 전달받은 전체 데이터
    let tasks: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            // 타이틀 '전체 할 일'로 변경 (이미지 우측 하단 참조)
            Text("전체 할 일")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            ScrollView {
                VStack{
                    // 전달받은 모든 task 표시
                    ForEach(tasks, id: \.self) { task in
                        HStack {
                            Text(task)
                                .font(.body)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding()
    }
}

// MARK: - 프리뷰
#Preview {
    HomeView()
}

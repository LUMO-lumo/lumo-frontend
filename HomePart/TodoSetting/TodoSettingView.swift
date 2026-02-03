//
//  TodosettingView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//
import SwiftUI
import Foundation
import Moya
import CombineMoya
import SwiftData

struct TodoSettingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HomeViewModel // HomeViewModel 연결
    
    // [수정] 인라인 수정을 위한 상태 변수
    // 현재 수정 중인 할 일의 ID를 추적합니다.
    @State private var editingTaskId: UUID?
    
    // UI 표시용 더미 데이터
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    // 달력 날짜 예시 (2025년 12월 기준)
    let calendarDays: [String] = [
        "", "1", "2", "3", "4", "5", "6",
        "7", "8", "9", "10", "11", "12", "13",
        "14", "15", "16", "17", "18", "19", "20",
        "21", "22", "23", "24", "25", "26", "27",
        "28", "29", "30", "31", "", "", ""
    ]
    
    // 메인 테마 색상 (이미지 참고: 코랄/오렌지 계열)
    let themeColor = Color(hex: "E86457")
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 헤더 (뒤로가기 + 타이틀)
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Text("오늘의 할 일")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 우측 균형을 맞추기 위한 빈 뷰
                Image(systemName: "chevron.left").opacity(0)
                    .frame(width: 20)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // 전체 콘텐츠 영역
            VStack(alignment: .leading, spacing: 0) {
                
                // 2. 년월 표시
                Text("2025년 12월")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                // 3. 캘린더
                VStack(spacing: 0) {
                    // 요일 헤더
                    HStack(spacing: 0) {
                        ForEach(days, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.top, 10)
                    
                    // 날짜 그리드
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 20) {
                        ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, day in
                            if day.isEmpty {
                                Text("")
                            } else {
                                Text(day)
                                    .font(.system(size: 16))
                                    .fontWeight(day == "22" ? .bold : .regular) // 22일 강조
                                    .foregroundStyle(day == "22" ? .white : .black)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        day == "22"
                                        ? Circle().fill(themeColor) // 선택된 날짜 배경
                                        : nil
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
                
                
                // 4. 할 일 리스트 (ViewModel 연결)
                // 리스트 영역에 높이 제한을 두고 내부 스크롤 적용
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        // [수정] Binding($)을 사용하여 데이터 실시간 연동
                        ForEach($viewModel.tasks) { $task in
                            TaskRow(
                                task: $task,
                                themeColor: themeColor,
                                isEditing: editingTaskId == task.id,
                                startEditing: {
                                    editingTaskId = task.id
                                },
                                finishEditing: {
                                    editingTaskId = nil
                                },
                                deleteAction: {
                                    deleteTask(task)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 5) // 위아래 살짝 여백
                }
                .frame(height: 220) // 약 3개 아이템이 보일 정도의 높이로 고정
                
                // 5. 작성하기 버튼
                Button(action: {
                    // 작성하기 액션
                }) {
                    Text("작성하기")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer() // 남은 공간 채우기
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // 할 일 삭제 함수
    private func deleteTask(_ task: Task) {
        if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
            // 애니메이션과 함께 삭제
            withAnimation {
                _ = viewModel.tasks.remove(at: index)
            }
        }
    }
}

// [수정] 리스트 아이템 뷰 (인라인 수정 기능 추가)
struct TaskRow: View {
    @Binding var task: Task // 데이터 수정을 위해 Binding 사용
    let themeColor: Color
    
    let isEditing: Bool          // 현재 수정 모드인지 여부
    let startEditing: () -> Void // 수정 시작 액션
    let finishEditing: () -> Void // 수정 완료 액션
    let deleteAction: () -> Void // 삭제 액션
    
    @FocusState private var isFocused: Bool // 텍스트 필드 포커스 제어
    
    var body: some View {
        HStack {
            if isEditing {
                // [수정 모드] TextField 표시
                TextField("할 일 입력", text: $task.title)
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .focused($isFocused) // 포커스 연결
                    .onSubmit { // 엔터 누르면 저장
                        finishEditing()
                    }
            } else {
                // [일반 모드] Text 표시
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.8))
            }
            
            Spacer()
            
            // 수정 아이콘 (연필 <-> 체크마크)
            Button(action: {
                if isEditing {
                    finishEditing() // 저장(완료)
                } else {
                    startEditing() // 수정 시작
                }
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(isEditing ? themeColor : .gray) // 수정 중일 때 색상 강조
            }
            .padding(.trailing, 8)
            
            // 삭제 아이콘 (휴지통 모양)
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(themeColor)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(hex: "FFF0EF")) // 리스트 아이템 배경 (연한 핑크)
        .cornerRadius(12)
        // 수정 모드가 되면 자동으로 포커스 주기
        .onChange(of: isEditing) { oldValue, newValue in
            if newValue {
                isFocused = true
            }
        }
    }
}

#Preview {
   // Preview용 더미 ViewModel 주입
   TodoSettingView(viewModel: HomeViewModel())
}

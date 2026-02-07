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
    @ObservedObject var viewModel: HomeViewModel // HomeView와 공유되는 ViewModel
    
    // [수정] 인라인 수정을 위한 상태 변수
    @State private var editingTaskId: UUID?
    
    // [추가] 달력의 기준이 되는 날짜 (기본값: 2025년 12월)
    @State private var targetDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    // 선택된 날짜 (문자열 날짜 "1", "22" 등)
    @State private var selectedDay: String = "22"
    
    // 요일 헤더
    let days = ["일", "월", "화", "수", "목", "금", "토"]
    
    // [수정] 실제 달력 데이터 계산 (Computed Property)
    // targetDate가 속한 달의 날짜 배열을 반환합니다. (앞쪽 빈칸 포함)
    var calendarDays: [String] {
        let calendar = Calendar.current
        
        // 1. 해당 월의 날짜 범위 가져오기 (예: 1~31일)
        guard let range = calendar.range(of: .day, in: .month, for: targetDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetDate)) else {
            return []
        }
        
        // 2. 해당 월의 1일이 무슨 요일인지 가져오기 (1: 일요일 ~ 7: 토요일)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 3. 앞쪽 빈칸 채우기 (1일이 수요일(4)이면 앞의 3칸은 비워야 함)
        let paddingDays = firstWeekday - 1
        var daysArray = Array(repeating: "", count: paddingDays)
        
        // 4. 날짜 채우기 (1부터 말일까지)
        for day in range {
            daysArray.append(String(day))
        }
        
        return daysArray
    }
    
    // [추가] 년월 표시용 포맷터
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월" // 예: 2025년 12월
        return formatter.string(from: targetDate)
    }
    
    // 더미 데이터들...
    let tasksFor23: [Task] = [
        Task(title: "크리스마스 케이크 예약", isCompleted: false, date: Date()),
        Task(title: "친구 선물 포장하기", isCompleted: false, date: Date()),
        Task(title: "파티룸 예약 확인", isCompleted: false, date: Date()),
        Task(title: "초대장 보내기", isCompleted: false, date: Date())
    ]
    
    let defaultTasks: [Task] = [
        Task(title: "일반쓰레기 버리기", isCompleted: false, date: Date()),
        Task(title: "영양제 챙겨 먹기", isCompleted: false, date: Date()),
        Task(title: "독서 30분 하기", isCompleted: false, date: Date())
    ]
    
    let themeColor = Color(hex: "E86457")
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 헤더
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray)
                }
                Spacer()
                Text("오늘의 할 일")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.left").opacity(0).frame(width: 20)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // 전체 콘텐츠 영역
            VStack(alignment: .leading, spacing: 0) {
                
                // 2. [수정] 동적 년월 표시
                HStack {
                    Text(monthTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // (선택사항) 달 이동 버튼이 필요하다면 여기에 추가 가능
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                // 3. 캘린더
                VStack(spacing: 0) {
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
                    
                    // [수정] 동적으로 계산된 calendarDays 사용
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 20) {
                        ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, day in
                            if day.isEmpty {
                                Text("")
                            } else {
                                let isSelected = (day == selectedDay)
                                
                                Text(day)
                                    .font(.system(size: 16))
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .foregroundStyle(isSelected ? .white : .black)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        isSelected
                                        ? Circle().fill(themeColor)
                                        : nil
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedDay = day
                                        }
                                        
                                        // 23일 더미 데이터 로직 유지
                                        if day == "23" {
                                            viewModel.tasks = tasksFor23
                                        } else {
                                            viewModel.tasks = defaultTasks
                                        }
                                        
                                        print("선택된 날짜: \(monthTitle) \(day)일")
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
                
                
                // 4. 할 일 리스트
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach($viewModel.tasks) { $task in
                            TaskRow(
                                task: $task,
                                themeColor: themeColor,
                                isEditing: editingTaskId == task.id,
                                startEditing: { editingTaskId = task.id },
                                finishEditing: { editingTaskId = nil },
                                deleteAction: { deleteTask(task) }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 5)
                }
                .frame(height: 220)
                
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
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // 할 일 삭제 함수
    private func deleteTask(_ task: Task) {
        if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation {
                _ = viewModel.tasks.remove(at: index)
            }
        }
    }
}

// 리스트 아이템 뷰
struct TaskRow: View {
    @Binding var task: Task
    let themeColor: Color
    
    let isEditing: Bool
    let startEditing: () -> Void
    let finishEditing: () -> Void
    let deleteAction: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("할 일 입력", text: $task.title)
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .focused($isFocused)
                    .onSubmit { finishEditing() }
            } else {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.8))
            }
            Spacer()
            Button(action: {
                if isEditing { finishEditing() } else { startEditing() }
            }) {
                Image(systemName: isEditing ? "checkmark.square.fill" : "square.and.pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(isEditing ? themeColor : .gray)
            }
            .padding(.trailing, 8)
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(themeColor)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(hex: "FFF0EF"))
        .cornerRadius(12)
        .onChange(of: isEditing) { oldValue, newValue in
            if newValue { isFocused = true }
        }
    }
}

#Preview {
   TodoSettingView(viewModel: HomeViewModel())
}

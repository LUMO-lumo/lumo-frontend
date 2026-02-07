//
//
//  TodoSettingView.swift
//  LUMO_PersonalDev
//
//  Created by 육도연 on 1/6/26.
//
import SwiftUI
import Foundation

struct TodoSettingView: View {
    @Environment(\.dismiss) var dismiss
    
    // 데이터 관리를 위한 메인 뷰모델
    @ObservedObject var viewModel: HomeViewModel
    
    // UI 상태 관리를 위한 전용 뷰모델
    @StateObject private var vm = TodoSettingViewModel()
    
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
            .padding(.bottom, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                // 2. 년월 표시
                Text(vm.monthTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                // 3. 캘린더 그리드
                calendarView
                
                // 4. 할 일 리스트 영역
                listView
                
                // 5. 작성하기 버튼
                Button(action: {
                    withAnimation {
                        vm.startCreatingTask()
                    }
                }) {
                    Text("작성하기")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(vm.isCreatingNewTask ? Color.gray : themeColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 10)
            }
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            vm.cancelNewTask()
            vm.editingTaskId = nil
        }
    }
    
    private var calendarView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(vm.days, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 20) {
                ForEach(Array(vm.calendarDays.enumerated()), id: \.offset) { _, day in
                    if day.isEmpty {
                        Text("").frame(width: 32, height: 32)
                    } else {
                        let isSelected = (day == vm.selectedDay)
                        Text(day)
                            .font(.system(size: 16))
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundStyle(isSelected ? .white : .black)
                            .frame(width: 32, height: 32)
                            .background(isSelected ? Circle().fill(themeColor) : nil)
                            .onTapGesture {
                                vm.cancelNewTask()
                                withAnimation(.spring()) {
                                    vm.selectDay(day)
                                }
                            }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }
    
    private var listView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 12) {
                    // [수정] ForEach 문법을 최신 SwiftUI 방식으로 간결하게 변경
                    // $viewModel.tasks를 사용하면 클로저 내부에서 $task라는 Binding을 바로 얻을 수 있습니다.
                    ForEach($viewModel.tasks) { $task in
                        TaskRow(
                            task: $task,
                            themeColor: themeColor,
                            isEditing: vm.editingTaskId == task.id,
                            startEditing: {
                                vm.cancelNewTask()
                                vm.editingTaskId = task.id
                            },
                            finishEditing: { vm.editingTaskId = nil },
                            deleteAction: {
                                viewModel.deleteTask(id: task.id)
                            }
                        )
                    }
                    
                    if vm.isCreatingNewTask {
                        NewTaskRow(
                            taskTitle: $vm.newTaskTitle,
                            themeColor: themeColor,
                            onConfirm: {
                                vm.addTask { title in
                                    withAnimation {
                                        viewModel.addTask(title: title)
                                    }
                                }
                            },
                            onCancel: { vm.cancelNewTask() }
                        )
                        .id("newTaskRow")
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 220)
            .onChange(of: vm.isCreatingNewTask) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("newTaskRow", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 하위 뷰 컴포넌트

struct TaskRow: View {
    // Task 타입 충돌 방지를 위해 명시적으로 지정하거나 상위에서 추론하게 둠
    @Binding var task: Task
    let themeColor: Color
    let isEditing: Bool
    let startEditing: () -> Void
    let finishEditing: () -> Void
    let deleteAction: () -> Void
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("수정", text: $task.title)
                    .font(.subheadline)
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
                Image(systemName: "square.and.pencil")
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
    }
}

struct NewTaskRow: View {
    @Binding var taskTitle: String
    let themeColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            TextField("할 일을 입력하세요", text: $taskTitle)
                .font(.subheadline)
                .focused($isFocused)
                .onSubmit { onConfirm() }
            
            Spacer()
            
            Button(action: onConfirm) {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(themeColor)
            }
            .padding(.trailing, 8)
            
            Button(action: onCancel) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(themeColor)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(hex: "FFF0EF"))
        .cornerRadius(12)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    TodoSettingView(viewModel: HomeViewModel())
}

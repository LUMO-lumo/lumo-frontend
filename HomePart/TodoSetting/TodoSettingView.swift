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
    @ObservedObject var viewModel: HomeViewModel
    @StateObject private var vm = TodoSettingViewModel()
    let themeColor = Color(hex: "E86457")
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    .foregroundStyle(.gray) }
                Spacer()
                Text("오늘의 할 일")
                    .font(.headline)
                    .bold()
                Spacer()
                Image(systemName: "chevron.left")
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(vm.monthTitle)
                    .font(.title3)
                    .bold()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                calendarView
                listView
                
                Button(action: { withAnimation { vm.startCreatingTask() } }) {
                    Text("작성하기")
                        .font(.headline)
                        .bold().foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "F55641"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24).padding(.vertical, 20)
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture { vm.cancelNewTask(); vm.editingTaskId = nil }
        .onAppear {
            // 진입 시점에 현재 선택된 날짜의 데이터 로드
            viewModel.loadTasksForSpecificDate(date: vm.resolvedSelectedDate)
        }
        .onChange(of: vm.resolvedSelectedDate) { _, newDate in
            // 달력 날짜가 바뀌면 즉시 해당 날짜 할 일만 로드
            viewModel.loadTasksForSpecificDate(date: newDate)
        }
    }
    
    private var calendarView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(vm.days, id: \.self) {
                    Text($0)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }.padding(.vertical, 10)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 20) {
                ForEach(Array(vm.calendarDays.enumerated()), id: \.offset) { _, day in
                    if day.isEmpty { Spacer().frame(width: 32, height: 32) }
                    else {
                        let isSelected = (day == vm.selectedDay)
                        Text(day)
                            .font(.system(size: 16))
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(width: 32, height: 32)
                            .background(isSelected ? Circle().fill(themeColor) : nil)
                            .onTapGesture {
                                vm.cancelNewTask()
                                withAnimation { vm.selectDay(day) }
                            }
                    }
                }
            }
        }.padding(.horizontal, 24).padding(.bottom, 20)
    }
    
    private var listView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.tasks.isEmpty && !vm.isCreatingNewTask {
                        Text("이 날은 할 일이 없습니다.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                    } else {
                        ForEach($viewModel.tasks) { $task in
                            TaskRow(task: $task, themeColor: themeColor,
                                    isEditing: vm.editingTaskId == task.id,
                                    startEditing: { vm.cancelNewTask(); vm.editingTaskId = task.id },
                                    finishEditing: { vm.editingTaskId = nil },
                                    deleteAction: { viewModel.deleteTask(id: task.id) })
                        }
                    }
                    
                    if vm.isCreatingNewTask {
                        NewTaskRow(taskTitle: $vm.newTaskTitle, themeColor: themeColor,
                                   onConfirm: {
                                       if let title = vm.handleTaskSubmission() {
                                           // 선택된 날짜 정보를 넘겨서 저장
                                           viewModel.addTask(title: title, date: vm.resolvedSelectedDate)
                                       }
                                   },
                                   onCancel: { vm.cancelNewTask() }).id("newTaskRow")
                    }
                }.padding(.horizontal, 24)
            }
            .frame(height: 220)
            .onChange(of: vm.isCreatingNewTask) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo("newTaskRow", anchor: .bottom) }
                    }
                }
            }
        }
    }
}

struct TaskRow: View {
    @Binding var task: Task
    let themeColor: Color
    let isEditing: Bool
    let startEditing: () -> Void
    let finishEditing: () -> Void
    let deleteAction: () -> Void
    var body: some View {
        HStack {
            if isEditing { TextField("수정", text: $task.title).font(.subheadline).onSubmit { finishEditing() } }
            else { Text(task.title).font(.subheadline).foregroundStyle(.primary) }
            Spacer()
            Button(action: {
                isEditing ? finishEditing() : startEditing()
            }) {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(isEditing ? themeColor : .gray)
            }
            Button(action: deleteAction) { Image(systemName: "trash").foregroundStyle(themeColor) }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
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
            Button(action:
                    onConfirm) { Image(systemName: "checkmark.square.fill").foregroundStyle(themeColor) }
            Button(action: onCancel) { Image(systemName: "trash").foregroundStyle(themeColor) }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12).onAppear { isFocused = true }
    }
}


#Preview {
    TodoSettingView(viewModel: HomeViewModel())
}

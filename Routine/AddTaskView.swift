//
//  AddTaskSheet.swift
//  Lumo
//
//  Created by 김승겸 on 1/22/26.
//
import SwiftUI

struct AddTaskSheet: View {
    @Bindable var viewModel: RoutineViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("루틴 생성하기")
                .font(.headline)
                .padding(.top)
            
            // 현재 어떤 탭에 추가하는지 알려줌
            if let type = viewModel.selectedType {
                Text("'\(type.title)'에 추가됩니다")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            TextField("루틴 이름을 입력해주세요", text: $viewModel.inputTaskTitle)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            Spacer()
            
            Button {
                viewModel.addRoutine()
                isPresented = false
            } label: {
                Text("생성하기")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isTaskSaveDisabled ? Color.gray : Color.orange)
                    .cornerRadius(12)
            }
            .disabled(viewModel.isTaskSaveDisabled)
        }
        .padding()
    }
}

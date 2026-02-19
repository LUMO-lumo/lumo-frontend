//
//  AddTypeSheed.swift
//  Lumo
//
//  Created by 김승겸 on 1/22/26.
//
import SwiftUI
import SwiftData

struct AddTypeSheet: View {
    @Bindable var viewModel: RoutineViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            
            Text("타입 추가하기")
                .font(.Subtitle2)
            
            TextField("타입 이름을 입력해주세요", text: $viewModel.inputTypeTitle)
                .font(.Subtitle3)
                .foregroundStyle(Color(hex: "979DA7"))
                .padding(.vertical, 17)
                .padding(.horizontal, 20)
                .background(Color(hex: "F2F4F7"))
                .cornerRadius(8)
            
            Button {
                viewModel.addRoutineType()
                isPresented = false
            } label: {
                Text("추가하기")
                    .font(.Subtitle3)
                    .foregroundStyle(viewModel.isTypeSaveDisabled ? Color.black : Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isTypeSaveDisabled ? Color(hex: "DDE1E8") : Color(hex: "F55641"))
                    .cornerRadius(12)
            }
            .disabled(viewModel.isTypeSaveDisabled)
            
            Spacer()
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 30)
        .background(Color.white)
    }
}

#Preview {
    @Previewable @State var isPresented = true
    let container = try! ModelContainer(for: RoutineType.self, RoutineTask.self)
    let viewModel = RoutineViewModel(modelContext: container.mainContext)
    AddTypeSheet(viewModel: viewModel, isPresented: $isPresented)
}

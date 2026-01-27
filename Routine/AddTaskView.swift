//
//  AddTaskView.swift
//  Lumo
//
//  Created by 김승겸 on 1/22/26.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Bindable var viewModel: RoutineViewModel
    @Environment(\.dismiss) var dismiss
    
    @Binding var isTabBarHidden: Bool
    
    // 선택 가능한 루틴 타입 목록을 불러옵니다.
    @Query(sort: \RoutineType.createdAt) var routineTypes: [RoutineType]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            
            // 루틴 이름 입력 필드
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("루틴 이름을 입력해주세요", text: $viewModel.inputTaskTitle)
                        .font(.Subtitle3)
                        .foregroundStyle(Color(hex: "979DA7"))
                    
                    Image("pencil")
                        .foregroundStyle(Color(hex: "979DA7"))
                    
                }
                .padding(.vertical, 17)
                .padding(.horizontal, 20)
                .background(Color(hex: "F2F4F7"))
                .cornerRadius(8)
            }
            .padding(.top, 32)
            
            // 루틴 타입 선택 섹션
            VStack(alignment: .leading, spacing: 20) {
                Text("루틴 타입")
                    .font(.Body1)
                    .foregroundStyle(.black)
                
                // 루틴 타입 리스트 (체크박스 형태)
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(routineTypes) { type in
                        Button {
                            // 버튼을 누르면 뷰모델의 선택된 타입을 변경
                            viewModel.selectedType = type
                        } label: {
                            HStack(spacing: 10) {
                                // 체크박스 아이콘
                                if viewModel.selectedType == type {
                                    Image("typeCheck")
                                        .foregroundStyle(Color.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color(hex: "F55641"))
                                        .cornerRadius(4)
                                } else {
                                    Color.clear
                                        .frame(width: 16, height: 16)
                                        .cornerRadius(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color(hex: "DDE1E8"))
                                        )
                                }
                                
                                // 타입 이름
                                Text(type.title)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.black)
                                
                                Spacer()
                            }
                            .contentShape(Rectangle()) // 빈 공간도 터치되도록
                        }
                    }
                }
            }
            
            Spacer()
            
            // 생성하기 버튼
            Button {
                viewModel.addRoutine()
                dismiss()
            } label: {
                Text("생성하기")
                    .font(.Subtitle3)
                    .foregroundStyle(viewModel.isTaskSaveDisabled ? Color(hex: "404348") : Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(viewModel.isTaskSaveDisabled ? Color(hex: "DDE1E8") : Color(hex: "F55641"))
                    .cornerRadius(8)
            }
            .disabled(viewModel.isTaskSaveDisabled)
            
            
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 25)
        .background(Color.white)
        
        // 네비게이션 설정
        //        .navigationTitle("루틴 생성하기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 1. 기본 버튼 숨기기
        .toolbar {
            // 2. 왼쪽 상단(Leading)에 버튼 배치
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss() // 3. 버튼 클릭 시 뒤로가기
                } label: {
                    // 디자인 시안에 맞는 아이콘 사용 (예: chevron.left)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold)) // 두께 조정
                        .foregroundStyle(Color(hex: "979DA7")) // 색상 조정 (보통 검정 또는 회색)
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItem(placement: .principal) {
                Text("루틴 생성하기")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
        // 화면이 나타날 때 탭바 숨기기
        .onAppear {
            isTabBarHidden = true
        }
        
        // 화면이 사라질 때 탭바 다시 보이기
        .onDisappear {
            isTabBarHidden = false
        }
    }
}

// MARK: - 프리뷰
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RoutineType.self, RoutineTask.self, configurations: config)
    
    // 더미 데이터 추가
    let type1 = RoutineType(title: "데일리")
    let type2 = RoutineType(title: "시험기간")
    container.mainContext.insert(type1)
    container.mainContext.insert(type2)
    
    let viewModel = RoutineViewModel(modelContext: container.mainContext)
    
    // 초기 선택값 설정 (테스트용)
    viewModel.selectedType = type1
    
    return NavigationStack {
        AddTaskView(viewModel: viewModel, isTabBarHidden: .constant(true))
    }
}

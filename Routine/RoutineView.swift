//
//  RoutineView.swift
//  Lumo
//
//  Created by 김승겸 on 1/17/26.
//

import SwiftUI
import SwiftData

struct RoutineView: View {
    @Environment(\.modelContext) var modelContext
    @State private var viewModel: RoutineViewModel?
    
    // DB에서 루틴 타입(탭)들을 생성일 순서대로 가져옴
    @Query(sort: \RoutineType.createdAt) var routineTypes: [RoutineType]
    
    // UI 상태 관리
    @State private var showAddTypeSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                
                // 루틴 타입 탭바
                if let vm = viewModel {
                    RoutineTabBar(
                        routineTypes: routineTypes,
                        selectedType: Bindable(vm).selectedType,
                        onAddTypeTap: { showAddTypeSheet = true }
                    )
                    .padding(.top, 14)
                    .padding(.bottom, 40)
                }
                
                Text("\(viewModel?.selectedType?.title ?? "") 루틴")
                    .font(.Subtitle1)
                    .foregroundStyle(Color.black)
                    .padding(.bottom, 19)
                
                // 루틴 리스트
                if let vm = viewModel, let selectedType = vm.selectedType {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(selectedType.tasks ?? []) { task in
                                RoutineCardView(task: task) {
                                    vm.toggleTask(task)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                } else {
                    Spacer()
                    if routineTypes.isEmpty {
                        Text("데이터를 불러오는 중이거나 탭이 없습니다.")
                            .foregroundStyle(.gray)
                    } else {
                        Text("상단 탭을 선택해주세요.")
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                
                // 루틴 생성하기 버튼
                if let vm = viewModel {
                    VStack {
                        NavigationLink {
                            AddTaskView(viewModel: vm)
                        } label: {
                            Text("생성하기")
                                .font(.Subtitle3)
                                .foregroundStyle(Color(hex: "404347"))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(Color(hex: "DDE1E8"))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 133)
                }
            }
            .padding(.horizontal, 25)
            .navigationTitle("나의 루틴")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel == nil {
                    viewModel = RoutineViewModel(modelContext: modelContext)
                }
                viewModel?.checkAndCreateDefaultCategories()
                viewModel?.checkDailyReset()
                
                if viewModel?.selectedType == nil, let first = routineTypes.first {
                    viewModel?.selectedType = first
                }
            }
            .onChange(of: routineTypes) { old, new in
                if viewModel?.selectedType == nil, let first = new.first {
                    viewModel?.selectedType = first
                }
            }
            .sheet(isPresented: $showAddTypeSheet) {
                if let vm = viewModel {
                    AddTypeSheet(viewModel: vm, isPresented: $showAddTypeSheet)
                        .presentationDetents([.fraction(0.3)])
                }
            }
        }
    }
}

#Preview {
    RoutineView()
        .modelContainer(for: [RoutineType.self, RoutineTask.self], inMemory: true)
}

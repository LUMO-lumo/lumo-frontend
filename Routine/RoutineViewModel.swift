//
//  RoutineViewModel.swift
//  Lumo
//
//  Created by 김승겸 on 1/19/26.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class RoutineViewModel {
    
    private var modelContext: ModelContext
    
    // MARK: - 입력 상태 관리
    // 사용자가 입력하는 동안 이 변수들에 값이 저장됨
    var inputSelectedType: RoutineType = .daily // 기본 루틴 타입
    var inputTitle: String = ""
    var inputDetail: String = ""
    
    // MARK: - 생성 버튼 활성화 조건
    // 저장 버튼 활성화 여부 (제목이 비어있으면 버튼 비활성화)
    var isSaveButtonDisabled: Bool {
        return inputTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 루틴 생성
    func addRoutine() {
        // 제목이 없으면 저장하지 않음
        guard !inputTitle.isEmpty else { return }
        
        // 선택 입력값
        // 입력된 내용이 없으면 nil로 저장, 있으면 그대로 저장
        let detailText: String? = inputDetail.isEmpty ? nil : inputDetail
        
        // 모델 생성
        let newTask = RoutineTask(
            type: inputSelectedType,
            title: inputTitle,
            detail: detailText
        )
        
        // 저장
        modelContext.insert(newTask)
        
        // 다음 생성을 위한 입력창 초기화
        resetInputFields()
        
        print("루틴 생성 완료: \(newTask.title) (\(newTask.type.rawValue))")
    }
    
    func resetInputFields() {
        inputTitle = ""
        inputDetail = ""
        inputSelectedType = .daily
    }
    
    // MARK: - 체크/해제 토글 및 연속달성 계산
    func toggleTask(_ task: RoutineTask) {  // 사용자가 체크 버튼을 눌렀음
        let calendar = Calendar.current
        let today = Date()
        
        // 버튼이 이미 체크(True)되어 있는가?
        if task.isCompleted {
            // 이미 체크된 걸 눌렀으니 해제하게 됨
            task.isCompleted = false    // 루틴을 미완료 상태로 변경
            task.currentStreak = max(0, task.currentStreak - 1)
            
        } else {
            // 미완료 상태였을 때 체크 버튼을 누름
            task.isCompleted = true // 루틴을 완료 상태로 변경
            
            // 날짜 비교하는 로직
            if let lastDate = task.lastCompletedDate {
                if calendar.isDateInToday(lastDate) {
                    // 1. 오늘 이미 체크했다가 취소하고 다시 체크한 경우
                    // 스트릭을 다시 올리기만 하면 됨 (날짜 갱신 불필요)
                    task.currentStreak += 1
                } else if calendar.isDateInYesterday(lastDate) {
                    // 2. 어제 체크 후 오늘 연속으로 체크하는 경우 (연속 달성)
                    task.currentStreak += 1
                    task.lastCompletedDate = today
                } else {
                    // 3. 어제 체크 안 했음 (연속 깨짐)
                    task.currentStreak = 1
                    task.lastCompletedDate = today
                }
            } else {
                // 4. 처음 체크하는 경우
                task.currentStreak = 1
                task.lastCompletedDate = today
            }
        }
        // SwiftData는 자동 저장을 지원하지만, 즉시 저장을 위해 명시적으로 저장할 수 있다
        try? modelContext.save()
    }
    
    // MARK: - 자정 지났을 때 초기화 (앱 실행 시 + 자정 감지 시 호출)
    func checkDailyReset() {
        // SwiftData에서 데이터를 직접 가져와서 검사
        // SwiftData에서 모든 Task를 가져오기 위한 FetchDescriptor
        let descriptor = FetchDescriptor<RoutineTask>()
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            
            for task in allTasks {
                // 마지막 완료일이 오늘이 아니라면 (어제나 엊그제일 경우)
                if let lastDate = task.lastCompletedDate,
                   !calendar.isDateInToday(lastDate) {
                    // 체크 상태를 해제하여 회색으로 되돌림
                    if task.isCompleted {
                        task.isCompleted = false
                    }
                }
            }
        } catch  {
            print("데이터 로드 실패: \(error)")
        }
    }
    
}

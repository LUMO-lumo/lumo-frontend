//
//  RoutineTabBar.swift
//  Lumo
//
//  Created by 김승겸 on 1/21/26.
//

import SwiftUI

struct RoutineTabBar: View {
    var routineTypes: [RoutineType]
    @Binding var selectedType: RoutineType?
    var onAddTypeTap: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 생성된 탭들
                ForEach(routineTypes) { type in
                    Button {
                        selectedType = type
                    } label: {
                        Text(type.title)
                            .font(.Body1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(type == selectedType ? Color(hex: "F55641") : Color.white)
                            .cornerRadius(20)
                            .foregroundStyle(type == selectedType ? Color.white : Color(hex: "979DA7"))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(type == selectedType ? Color.clear : Color(hex: "BBC0C7"), lineWidth: 1)
                            }
                        
                    }
                }
                
                // + 타입 추가 버튼
                Button {
                    onAddTypeTap()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                        Text("타입 추가")
                    }
                    .font(.Body1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .foregroundStyle(Color(hex: "979DA7"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "BBC0C7"), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

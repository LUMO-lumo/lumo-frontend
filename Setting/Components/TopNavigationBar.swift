//
//  TopNavigationBar.swift
//  Lumo
//
//  Created by 정승윤 on 2/3/26.
//

import Foundation
import SwiftUI

struct TopNavigationBar: ViewModifier {
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    func body(content: Content) -> some View {
        VStack{
            ZStack{
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .background(Color.white)
            
            Spacer().frame(height:32)
            
            content
        }
    }
}

extension View {
    func topNavigationBar(title: String) -> some View {
        self.modifier(TopNavigationBar(title: title))
    }
}


//
//  SupportSectionView.swift
//  Lumo
//
//  Created by 김승겸 on 1/30/26.
//

import SwiftUI

struct SupportSectionView: View {
    var body: some View {
        HStack {
            
            NavigationLink(destination: DistanceMissionView(alarmId: 1)) {
                Text("자주 묻는 질문")
                    .font(.Body1)
                    .padding(.vertical, 18)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray400)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            NavigationLink(destination: Text("BM")) {
                Text("BM")
                    .font(.Body1)
                    .padding(.vertical, 18)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray400)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    SupportSectionView()
}

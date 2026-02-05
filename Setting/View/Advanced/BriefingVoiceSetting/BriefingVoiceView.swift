//
//  BriefingVoiceView.swift
//  Lumo
//
//  Created by 정승윤 on 2/5/26.
//

import SwiftUI

struct BriefingVoiceView: View {
    @State private var viewModel = BriefingVoiceViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let options = ["WOMAN", "MAN", "Pro"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
        List {
            ForEach(options, id: \.self) { voice in
                Button(action: {
                    viewModel.updateVoice(voice: voice)
                }) {
                    HStack(spacing: 10) {
                        ZStack{
                            Circle()
                                .foregroundColor(.gray300)
                                .frame(width:60, height:60)
                            Image(voice == "WOMAN" ? "Woman" : (voice == "MAN" ? "Man" : "Pro"))
                                .resizable()
                                .scaledToFill()
                                .frame(width:60, height:60)
                        }
                        Text(voice == "WOMAN" ? "여자" : (voice == "MAN" ? "남자" : "Pro"))
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .bold))
                        
                        Spacer()
                        
                        ZStack{
                            Circle()
                                .stroke(viewModel.selectedVoice == voice ? Color.main300 : Color.gray, lineWidth: 1)
                                .frame(width:16, height:16)
                                .foregroundColor(.main300)
                            if viewModel.selectedVoice == voice {
                                Circle()
                                    .frame(width:8, height:8)
                                    .foregroundColor(.main300)
                            }
                        }
                    }
                    Spacer().frame(height:10)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
    .topNavigationBar(title: "브리핑 목소리")
    .navigationBarHidden(true)
    }
}

#Preview {
    BriefingVoiceView()
}

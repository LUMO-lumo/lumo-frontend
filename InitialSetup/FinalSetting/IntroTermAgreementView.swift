//
//  IntroTermAgreementView.swift
//  Lumo
//
//  Created by 김승겸 on 1/26/26.
//

import SwiftUI

struct IntroTermAgreementView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @Binding var currentPage: Int
    
    // MARK: - 약관 동의 상태 변수들
    @State private var isTerm1Agreed = false // (필수) 이용약관
    @State private var isTerm2Agreed = false // (필수) 개인정보
    @State private var isTerm3Agreed = false // (선택) 위치정보
    @State private var isTerm4Agreed = false // (선택) 마케팅
    
    // 전체 동의 상태 (모두 true일 때만 true)
    private var isAllAgreed: Bool {
        isTerm1Agreed && isTerm2Agreed && isTerm3Agreed && isTerm4Agreed
    }
    
    // 필수 약관이 모두 동의되었는지 확인 (버튼 활성화용)
    private var isEssentialAgreed: Bool {
        isTerm1Agreed && isTerm2Agreed
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("서비스 사용을 위하여\n약관 동의가 필요해요")
                .font(.Subtitle1)
                .padding(.top, 37)
            
            Spacer()
            
            VStack(alignment: .leading) {
                
                // MARK: 전체 동의 버튼
                Button {
                    toggleAll()
                } label: {
                    HStack(spacing: 10) {
                        // 체크박스 UI (함수로 분리)
                        CheckboxView(isSelected: isAllAgreed, color: .gray700)
                        
                        Text("전체 동의")
                            .font(.pretendardSemiBold18)
                            .foregroundStyle(.black) // 버튼이라 명시적 색상 지정 필요
                    }
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.gray300)
                    .padding(.vertical, 12)
                
                VStack(spacing: 18) {
                    
                    // MARK: (필수) 이용약관 동의
                    HStack(spacing: 10) {
                        Button {
                            isTerm1Agreed.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                CheckboxView(isSelected: isTerm1Agreed, color: .gray400)
                                Text("\(Text("(필수)").foregroundStyle(Color.main300)) 이용약관 동의")
                                    .foregroundStyle(.black)
                                    .font(.pretendardMedium18)
                            }
                        }
                        
                        Spacer()
                        
                        // 상세보기 버튼 (별도 동작)
                        Button {
                            // 상세 페이지 이동 로직
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.gray300)
                        }
                        .frame(width: 44, height: 44)
                    }
                    
                    // MARK: (필수) 개인정보 수집 및 이용동의
                    HStack(spacing: 10) {
                        Button {
                            isTerm2Agreed.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                CheckboxView(isSelected: isTerm2Agreed, color: .gray400)
                                Text("\(Text("(필수)").foregroundStyle(Color.main300)) 개인정보 수집 및 이용동의")
                                    .foregroundStyle(.black)
                                    .font(.pretendardMedium18)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.gray300)
                        }
                        .frame(width: 44, height: 44)
                    }
                    
                    // MARK: (선택) 위치정보서비스 이용약관
                    HStack(spacing: 10) {
                        Button {
                            isTerm3Agreed.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                CheckboxView(isSelected: isTerm3Agreed, color: .gray400)
                                Text("\(Text("(선택)").foregroundStyle(Color.gray400)) 위치정보서비스 이용약관")
                                    .foregroundStyle(.black)
                                    .font(.pretendardMedium18)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.gray300)
                        }
                        .frame(width: 44, height: 44)
                    }
                    
                    // MARK: (선택) 마케팅 활용 동의
                    HStack(spacing: 10) {
                        Button {
                            isTerm4Agreed.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                CheckboxView(isSelected: isTerm4Agreed, color: .gray400)
                                Text("\(Text("(선택)").foregroundStyle(Color.gray400)) 마케팅 활용/광고성 정보 수신동의")
                                    .foregroundStyle(.black)
                                    .font(.pretendardMedium18)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.gray300)
                        }
                        .frame(width: 44, height: 44)
                    }
                    
                }
                .padding(.bottom, 44)
            }
            
            // MARK: 시작하기 버튼
            Button(action: {
                // 필수 약관 동의 시에만 넘어감
                if isEssentialAgreed {
                    viewModel.path.append(OnboardingStep.home)
                }
            }) {
                Text("시작하기")
                    .font(.Subtitle3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.white)
                    // 필수 약관 미동의 시 버튼 색상 흐리게 처리 (UX 옵션)
                    .background(isEssentialAgreed ? Color.main300 : Color.gray300)
                    .cornerRadius(8)
            }
            .disabled(!isEssentialAgreed) // 필수 약관 미동의 시 버튼 비활성화
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
    }
    
    /// 전체 동의 토글 로직
    private func toggleAll() {
        if isAllAgreed {
            // 이미 모두 동의 상태라면 전부 해제
            isTerm1Agreed = false
            isTerm2Agreed = false
            isTerm3Agreed = false
            isTerm4Agreed = false
        } else {
            // 하나라도 비동의라면 전부 동의 처리
            isTerm1Agreed = true
            isTerm2Agreed = true
            isTerm3Agreed = true
            isTerm4Agreed = true
        }
    }
    
    /// 체크박스 디자인 컴포넌트
    @ViewBuilder
    private func CheckboxView(isSelected: Bool, color: Color) -> some View {
        if isSelected {
            // 선택되었을 때
            Image("typeCheck")
                .renderingMode(.template)
                .foregroundStyle(Color.white)
                .frame(width: 16, height: 16)
                .background(Color.main300)
                .cornerRadius(4)
        } else {
            // 선택되지 않았을 때
            Rectangle()
                .frame(width: 16, height: 16)
                .cornerRadius(4)
                .foregroundStyle(Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color)
                }
        }
    }
}

#Preview {
    IntroTermAgreementView(currentPage: .constant(3))
        .environment(OnboardingViewModel())
}

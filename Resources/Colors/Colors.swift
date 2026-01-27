//
//  Colors.swift
//  Lumo
//
//  Created by 김승겸 on 1/26/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double((rgb >>  0) & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    static let main300 = Color(hex: "F55641")
    
    static let main200 = Color(hex: "F59241")
    
    static let main100 = Color(hex: "FFE747")
    
    static let gray800 = Color(hex: "25272A")
    
    static let gray700 = Color(hex: "404347")
    
    static let gray600 = Color(hex: "7A7F88")
    
    static let gray500 = Color(hex: "979DA7")
    
    static let gray400 = Color(hex: "BBC0C7")
    
    static let gray300 = Color(hex: "DDE1E8")
    
    static let gray200 = Color(hex: "F2F4F7")
}


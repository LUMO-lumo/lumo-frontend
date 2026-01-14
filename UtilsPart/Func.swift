//
//  Func.swift
//  LUMO_MainDev
//
//  Created by 육도연 on 1/9/26.
//

import Foundation
import SwiftUI
import Combine

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
}

//
//  LessyMascotView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 07/01/2026.
//

import SwiftUI

// MARK: - Mascot Image View
struct LessyMascotView: View {
    let size: CGSize
    
    init(size: CGSize = CGSize(width: 200, height: 200)) {
        self.size = size
    }
    
    var body: some View {
        Image("mascott")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
    }
}

// MARK: - Mascot Container with Effects
struct LessyMascotContainer: View {
    var size: CGFloat = 200
    var showGlow: Bool = true
    var glowColor: Color = Color(hex: "ffb3cf")
    
    var body: some View {
        ZStack {
            // Glow effect behind mascot
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glowColor.opacity(0.3), glowColor.opacity(0)],
                            center: .center,
                            startRadius: size * 0.2,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
                    .blur(radius: 20)
            }
            
            // Mascot image
            LessyMascotView(size: CGSize(width: size, height: size))
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "111111")
            .ignoresSafeArea()
        
        LessyMascotContainer(size: 200)
    }
}


//
//  LessyMascotView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 07/01/2026.
//

import SwiftUI
import AVFoundation
import AVKit

// MARK: - UIKit TransparentVideoView
class TransparentVideoView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    func play(url: URL) {
        // Clean up any existing player
        stop()
        
        // Create player item
        let playerItem = AVPlayerItem(url: url)
        
        // Use AVQueuePlayer with AVPlayerLooper for seamless looping
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)
        
        // Setup player layer
        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = bounds
        playerLayer?.pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
        
        // Start playback
        queuePlayer?.play()
    }
    
    func stop() {
        queuePlayer?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        queuePlayer = nil
        playerLooper = nil
    }
    
    deinit {
        stop()
    }
}

// MARK: - SwiftUI Wrapper
struct LessyMascotView: UIViewRepresentable {
    let animationURL: URL
    let size: CGSize
    
    init(size: CGSize = CGSize(width: 200, height: 200)) {
        self.animationURL = URL(string: "https://assets.masco.dev/ac760a/lessy-1986/deep-meditative-breath-afeb554b.mov")!
        self.size = size
    }
    
    func makeUIView(context: Context) -> TransparentVideoView {
        let view = TransparentVideoView()
        view.backgroundColor = .clear
        view.isOpaque = false
        return view
    }
    
    func updateUIView(_ uiView: TransparentVideoView, context: Context) {
        uiView.play(url: animationURL)
    }
    
    static func dismantleUIView(_ uiView: TransparentVideoView, coordinator: ()) {
        uiView.stop()
    }
}

// MARK: - Mascot Container with Effects
struct LessyMascotContainer: View {
    var size: CGFloat = 200
    var showGlow: Bool = true
    var glowColor: Color = Color(hex: "ffb3cf")
    
    @State private var isFloating = false
    @State private var glowPulse = false
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            // Glow effect behind mascot (with pulse animation)
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
                    .scaleEffect(glowPulse ? 1.1 : 1.0)
                    .opacity(glowPulse ? 0.8 : 1.0)
            }
            
            // Mascot video with floating animation
            LessyMascotView(size: CGSize(width: size, height: size))
                .frame(width: size, height: size)
                .offset(y: isFloating ? -6 : 6)
                .scaleEffect(hasAppeared ? 1.0 : 0.7)
        }
        .onAppear {
            // Entry bounce animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                hasAppeared = true
            }
            
            // Continuous floating animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isFloating = true
            }
            
            // Glow pulse animation
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = true
            }
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

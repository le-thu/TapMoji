//
//  ContentView.swift
//  TapMoji
//
//  Created by Thu Le on 19/1/26.
//

import SwiftUI
import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()

    private init() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? audioEngine.start()
    }

    func playPop() {
        playTone(freq: 180, duration: 0.12, decay: 20, pitchDrop: true)
    }

    func playClick() {
        playTone(freq: 120, duration: 0.06, decay: 60, pitchDrop: false)
    }

    private func playTone(freq: Double, duration: Double, decay: Double, pitchDrop: Bool) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let f = pitchDrop ? freq * (1 + exp(-t * 40) * 2) : freq
            let sample = sin(2 * .pi * f * t) * exp(-t * decay)
            buffer.floatChannelData![0][i] = Float(sample) * 0.6
        }

        playerNode.stop()
        playerNode.scheduleBuffer(buffer)
        playerNode.play()
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var currentEmoji = "🍕"
    @State private var bounceScale: CGFloat = 1.0
    @AppStorage("themeMode") private var themeMode = "System"

    let emojis = [
        "🍕", "🍔", "🍟", "🌭", "🍿", "🥐", "🥯", "🍞", "🥨", "🧀",
        "🥚", "🍳", "🥓", "🍖", "🍗", "🥩", "🌮", "🌯", "🥗", "🍜",
        "🍝", "🍣", "🍱", "🥟", "🍛", "🍲", "🥘", "🫕", "🥣", "🧆",
        "🥙", "🫔", "🍙", "🍘", "🍥", "🥑", "🌽", "🥕", "🧅", "🧄",
        "🥦", "🫑", "🌶️", "🫒", "🥬", "🥒", "🍅", "🫛", "🥔", "🍆",
        "🫘", "🥜", "🫚", "🍄", "🧈", "🥫", "🫙",
    ]

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(white: 0.12) : Color(red: 0.98, green: 0.95, blue: 0.92))
                .ignoresSafeArea()

            Text(currentEmoji)
                .font(.system(size: 124))
                .scaleEffect(bounceScale)
                .offset(y: verticalSizeClass == .compact ? 0 : -40)
            
            VStack {
                Spacer()
                Picker("Theme", selection: $themeMode) {
                    Image(systemName: "circle.lefthalf.filled").tag("System")
                    Image(systemName: "sun.max.fill").tag("Light")
                    Image(systemName: "moon.fill").tag("Dark")
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                .scaleEffect(1.25)
                .padding(.bottom, 20)
            }
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            SoundManager.shared.playPop()
            currentEmoji = emojis.filter { $0 != currentEmoji }.randomElement() ?? "🍕"
            bounceScale = 1.25
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { bounceScale = 1.0 }
        }
        .preferredColorScheme(themeMode == "System" ? nil : (themeMode == "Dark" ? .dark : .light))
        .onChange(of: themeMode) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            SoundManager.shared.playClick()
        }
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  TapMoji
//
//  Created by Thu Le on 19/1/26.
//

import SwiftUI
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var popBuffer: AVAudioPCMBuffer?
    private var clickBuffer: AVAudioPCMBuffer?

    private init() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? audioEngine.start()

        popBuffer = makeTone(format: format, freq: 180, duration: 0.12, decay: 20, pitchDrop: true)
        clickBuffer = makeTone(format: format, freq: 120, duration: 0.06, decay: 60, pitchDrop: false)
    }

    func playPop() {
        play(popBuffer)
    }

    func playClick() {
        play(clickBuffer)
    }

    private func play(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer else { return }
        // Calls, Siri, and route changes stop the engine
        if !audioEngine.isRunning {
            do { try audioEngine.start() } catch { return }
        }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer)
        playerNode.play()
    }

    private func makeTone(format: AVAudioFormat, freq: Double, duration: Double, decay: Double, pitchDrop: Bool) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let f = pitchDrop ? freq * (1 + exp(-t * 40) * 2) : freq
            let sample = sin(2 * .pi * f * t) * exp(-t * decay)
            samples[i] = Float(sample) * 0.6
        }
        return buffer
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var currentEmoji = "🍕"
    @State private var bounceScale: CGFloat = 1.0
    @AppStorage("isDarkMode") private var isDarkMode = false

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
                Picker("Theme", selection: $isDarkMode) {
                    Image(systemName: "sun.max.fill").tag(false)
                    Image(systemName: "moon.fill").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                .scaleEffect(1.25)
                .padding(.bottom, 20)
            }
        }
        .onTapGesture {
            SoundManager.shared.playPop()
            currentEmoji = emojis.filter { $0 != currentEmoji }.randomElement() ?? "🍕"
            bounceScale = 1.25
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { bounceScale = 1.0 }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: currentEmoji)
        .sensoryFeedback(.impact(weight: .light), trigger: isDarkMode)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: isDarkMode) { _, _ in
            SoundManager.shared.playClick()
        }
    }
}

#Preview {
    ContentView()
}

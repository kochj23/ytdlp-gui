//
//  AudioWaveformView.swift
//  ytdlp-gui
//
//  Audio waveform visualization component
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct AudioWaveformView: View {
    let samples: [Float]
    let accentColor: Color
    let height: CGFloat

    @State private var animatedSamples: [Float] = []

    init(samples: [Float], accentColor: Color = ModernColors.cyan, height: CGFloat = 80) {
        self.samples = samples
        self.accentColor = accentColor
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            let displaySamples = animatedSamples.isEmpty ? samples : animatedSamples
            let barWidth = max(geometry.size.width / CGFloat(max(displaySamples.count, 1)) - 1, 1)

            HStack(alignment: .center, spacing: 1) {
                ForEach(Array(displaySamples.enumerated()), id: \.offset) { index, sample in
                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [accentColor.opacity(0.4), accentColor]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: barWidth, height: max(CGFloat(sample) * height, 2))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: height, alignment: .center)
        }
        .frame(height: height)
        .onAppear {
            // Animate bars appearing
            animatedSamples = samples.map { _ in Float(0) }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                animatedSamples = samples
            }
        }
    }
}

struct AudioWaveformCard: View {
    let filePath: String
    @State private var waveform: [Float]?
    @State private var audioInfo: (sampleRate: Double, channels: Int, duration: TimeInterval)?
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(ModernColors.purple)
                Text("Audio Preview")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Spacer()

                if let info = audioInfo {
                    HStack(spacing: 12) {
                        Label("\(Int(info.sampleRate))Hz", systemImage: "dial.low")
                        Label("\(info.channels)ch", systemImage: "speaker.wave.2")
                        Label(formatDuration(info.duration), systemImage: "clock")
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ModernColors.textTertiary)
                }
            }

            if isLoading {
                ProgressView("Generating waveform...")
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if let samples = waveform {
                AudioWaveformView(samples: samples, accentColor: ModernColors.purple)
            } else {
                Text("Could not generate waveform")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(ModernColors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
        .glassCard()
        .task {
            isLoading = true
            waveform = await AudioWaveformService.shared.generateWaveform(from: filePath)
            audioInfo = AudioWaveformService.shared.getAudioInfo(filePath: filePath)
            isLoading = false
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

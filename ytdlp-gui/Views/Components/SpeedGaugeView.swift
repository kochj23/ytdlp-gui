//
//  SpeedGaugeView.swift
//  ytdlp-gui
//
//  Circular speed gauge component (inspired by TopGUI)
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SpeedGaugeView: View {
    let speed: Double // bytes per second
    let maxSpeed: Double // for gauge scale
    let label: String

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard maxSpeed > 0 else { return 0 }
        return min(speed / maxSpeed, 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(90))

                // Progress arc
                Circle()
                    .trim(from: 0.15, to: 0.15 + animatedProgress * 0.7)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [ModernColors.cyan, ModernColors.accentGreen, ModernColors.yellow]),
                            center: .center,
                            startAngle: .degrees(180),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                // Center text
                VStack(spacing: 4) {
                    Text(formatSpeed(speed))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.textPrimary)
                    Text(label)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
            }
            .frame(width: 140, height: 140)
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: speed) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
    }

    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_000_000_000 {
            return String(format: "%.1f GB/s", bytesPerSecond / 1_000_000_000)
        } else if bytesPerSecond >= 1_000_000 {
            return String(format: "%.1f MB/s", bytesPerSecond / 1_000_000)
        } else if bytesPerSecond >= 1_000 {
            return String(format: "%.0f KB/s", bytesPerSecond / 1_000)
        } else {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
    }
}

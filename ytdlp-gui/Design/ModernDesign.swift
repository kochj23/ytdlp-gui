//
//  ModernDesign.swift
//  ytdlp-gui
//
//  Glassmorphic design system matching OneOnOne/TopGUI aesthetic
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ModernColors {
    // Dark blue gradient background
    static let gradientStart = Color(red: 0.08, green: 0.12, blue: 0.22)
    static let gradientMid = Color(red: 0.10, green: 0.15, blue: 0.28)
    static let gradientEnd = Color(red: 0.12, green: 0.18, blue: 0.32)

    // Vibrant accent colors
    static let cyan = Color(red: 0.3, green: 0.85, blue: 0.95)
    static let teal = Color(red: 0.2, green: 0.8, blue: 0.8)
    static let purple = Color(red: 0.6, green: 0.4, blue: 0.95)
    static let orange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let yellow = Color(red: 1.0, green: 0.85, blue: 0.3)
    static let pink = Color(red: 1.0, green: 0.35, blue: 0.65)
    static let accent = Color(red: 0.3, green: 0.85, blue: 0.95)
    static let blue = Color(red: 0.3, green: 0.6, blue: 1.0)
    static let accentBlue = Color(red: 0.3, green: 0.7, blue: 1.0)
    static let accentGreen = Color(red: 0.3, green: 0.9, blue: 0.6)
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    // Background blob colors
    static let blobCyan = Color(red: 0.2, green: 0.7, blue: 0.9)
    static let blobPurple = Color(red: 0.5, green: 0.3, blue: 0.8)
    static let blobPink = Color(red: 0.9, green: 0.3, blue: 0.6)
    static let blobOrange = Color(red: 0.9, green: 0.5, blue: 0.2)

    // Status colors
    static let statusLow = Color(red: 0.3, green: 0.9, blue: 0.6)
    static let statusMedium = Color(red: 1.0, green: 0.85, blue: 0.3)
    static let statusHigh = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let statusCritical = Color(red: 1.0, green: 0.3, blue: 0.4)

    // Additional colors
    static let red = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let green = Color(red: 0.3, green: 0.9, blue: 0.5)
    static let background = gradientStart

    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)

    // Glass card colors
    static let glassBackground = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.15)

    // Background gradient
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMid, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Heat map color based on percentage
    static func heatColor(percentage: Double) -> Color {
        switch percentage {
        case 0..<25: return statusLow
        case 25..<50: return statusMedium
        case 50..<75: return statusHigh
        default: return statusCritical
        }
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    let prominent: Bool

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(ModernColors.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .opacity(0.9)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(ModernColors.glassBorder, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
            )
    }
}

extension View {
    func glassCard(prominent: Bool = false) -> some View {
        modifier(GlassCard(prominent: prominent))
    }
}

// MARK: - Modern Button Style

struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let style: ButtonStyleType

    enum ButtonStyleType {
        case filled
        case outlined
        case destructive
        case glass
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if style == .glass {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                    } else if style == .filled || style == .destructive {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(configuration.isPressed ? color.opacity(0.8) : color)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color, lineWidth: 2)
                    }
                }
            )
            .foregroundColor(style == .outlined ? color : (style == .glass ? ModernColors.textPrimary : .white))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 5 : 8)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Modern Header

struct ModernHeader: ViewModifier {
    let size: HeaderSize

    enum HeaderSize {
        case large, medium, small

        var fontSize: CGFloat {
            switch self {
            case .large: return 32
            case .medium: return 22
            case .small: return 18
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
            .foregroundColor(ModernColors.textPrimary)
    }
}

extension View {
    func modernHeader(size: ModernHeader.HeaderSize = .large) -> some View {
        modifier(ModernHeader(size: size))
    }
}

// MARK: - Floating Blob

struct FloatingBlob: View {
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.6)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 50)
            .offset(x: x, y: y)
    }
}

// MARK: - Glassmorphic Background

struct GlassmorphicBackground: View {
    @State private var animateBlobs = false

    var body: some View {
        ZStack {
            ModernColors.backgroundGradient
                .ignoresSafeArea()

            FloatingBlob(
                color: ModernColors.blobCyan,
                size: 400,
                x: animateBlobs ? -100 : -150,
                y: animateBlobs ? -200 : -250
            )

            FloatingBlob(
                color: ModernColors.blobPurple,
                size: 350,
                x: animateBlobs ? 150 : 100,
                y: animateBlobs ? -150 : -100
            )

            FloatingBlob(
                color: ModernColors.blobPink,
                size: 450,
                x: animateBlobs ? 100 : 150,
                y: animateBlobs ? 300 : 350
            )

            FloatingBlob(
                color: ModernColors.blobOrange,
                size: 300,
                x: animateBlobs ? -200 : -150,
                y: animateBlobs ? 250 : 300
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateBlobs = true
            }
        }
    }
}

// MARK: - Sidebar Item Style

struct SidebarItemStyle: ViewModifier {
    let isSelected: Bool
    let color: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : Color.clear)
            )
            .foregroundColor(isSelected ? color : ModernColors.textSecondary)
    }
}

// MARK: - Circular Gauge

struct CircularGauge: View {
    let value: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let showValue: Bool
    let label: String?

    @State private var animatedValue: Double = 0

    init(value: Double, color: Color, size: CGFloat = 80, lineWidth: CGFloat = 8, showValue: Bool = true, label: String? = nil) {
        self.value = value
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.showValue = showValue
        self.label = label
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(animatedValue / 100.0, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: 6)

            if showValue {
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", animatedValue))
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                    if let label = label {
                        Text(label)
                            .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedValue = newValue
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func sidebarItem(isSelected: Bool, color: Color = ModernColors.accent) -> some View {
        modifier(SidebarItemStyle(isSelected: isSelected, color: color))
    }

    func formLabel() -> some View {
        self
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(ModernColors.textSecondary)
    }

    func formTextField() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .foregroundColor(ModernColors.textPrimary)
    }

    func primaryButton() -> some View {
        self
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ModernColors.cyan)
            .cornerRadius(10)
    }
}

//
//  PresetsView.swift
//  ytdlp-gui
//
//  Manage download presets
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct PresetsView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Presets")
                        .modernHeader(size: .large)
                    Spacer()
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    ForEach(dataStore.presets) { preset in
                        VStack(spacing: 12) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 32))
                                .foregroundColor(ModernColors.cyan)

                            Text(preset.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(ModernColors.textPrimary)

                            Text(preset.description)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            if preset.isBuiltIn {
                                Text("BUILT-IN")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(ModernColors.textTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .glassCard()
                    }
                }
            }
            .padding(32)
        }
    }
}

//
//  OutputTemplateBuilderView.swift
//  ytdlp-gui
//
//  Visual output filename template builder with variable chips
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct OutputTemplateBuilderView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var template: String = "%(title)s.%(ext)s"
    @State private var selectedCategory: OutputTemplateVariable.TemplateCategory = .video
    @State private var previewOutput: String = "My Video Title.mp4"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output Template")
                            .modernHeader(size: .large)
                        Text("Build custom filename templates for downloads")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                }

                // Current template
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(ModernColors.yellow)
                        Text("Template")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    TextField("%(title)s.%(ext)s", text: $template)
                        .font(.system(size: 14, design: .monospaced))
                        .formTextField()

                    // Preview
                    HStack {
                        Text("Preview:")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                        Text(previewOutput)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(ModernColors.accentGreen)
                    }

                    HStack(spacing: 8) {
                        Button("Apply") {
                            dataStore.settings.defaultOutputTemplate = template
                            dataStore.saveSettings()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))

                        Button("Reset") {
                            template = "%(title)s.%(ext)s"
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))
                    }
                }
                .glassCard()

                // Preset templates
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(ModernColors.orange)
                        Text("Preset Templates")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(OutputTemplatePreset.builtIn) { preset in
                            Button {
                                template = preset.template
                                updatePreview()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(ModernColors.textPrimary)
                                    Text(preset.template)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(ModernColors.cyan)
                                    Text(preset.description)
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundColor(ModernColors.textTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .glassCard()

                // Variable chips by category
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(ModernColors.teal)
                        Text("Available Variables")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    // Category picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(OutputTemplateVariable.TemplateCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Variable chips
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                        ForEach(OutputTemplateVariable.variables(for: selectedCategory)) { variable in
                            Button {
                                insertVariable(variable)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(variable.name)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(ModernColors.textPrimary)
                                    Text(variable.code)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(ModernColors.cyan)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(ModernColors.cyan.opacity(0.08))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .glassCard()
            }
            .padding(32)
        }
        .onAppear {
            template = dataStore.settings.defaultOutputTemplate
            updatePreview()
        }
        .onChange(of: template) { _ in
            updatePreview()
        }
    }

    private func insertVariable(_ variable: OutputTemplateVariable) {
        // Insert before the extension if present
        if template.hasSuffix(".%(ext)s") {
            let base = String(template.dropLast(8))
            template = base + " - " + variable.code + ".%(ext)s"
        } else {
            template += variable.code
        }
    }

    private func updatePreview() {
        let sampleValues: [String: String] = [
            "%(title)s": "My Video Title",
            "%(id)s": "dQw4w9WgXcQ",
            "%(ext)s": "mp4",
            "%(uploader)s": "Channel Name",
            "%(upload_date)s": "20260225",
            "%(resolution)s": "1920x1080",
            "%(height)s": "1080",
            "%(width)s": "1920",
            "%(fps)s": "30",
            "%(channel)s": "Channel Name",
            "%(playlist_title)s": "My Playlist",
            "%(playlist_index)s": "01",
            "%(n_entries)s": "25",
            "%(duration_string)s": "05:30",
            "%(release_year)s": "2026",
            "%(autonumber)s": "00001",
        ]

        var preview = template
        for (key, value) in sampleValues {
            preview = preview.replacingOccurrences(of: key, with: value)
        }
        previewOutput = preview
    }
}

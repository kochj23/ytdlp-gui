//
//  AudioWaveformService.swift
//  ytdlp-gui
//
//  Generate audio waveform data from audio files using AVFoundation
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import AVFoundation
import os

class AudioWaveformService {
    static let shared = AudioWaveformService()

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "AudioWaveform")

    // MARK: - Generate Waveform

    func generateWaveform(from filePath: String, sampleCount: Int = 200) async -> [Float]? {
        let url = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            logger.error("Audio file not found: \(filePath)")
            return nil
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)

            guard frameCount > 0 else { return nil }

            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try file.read(into: buffer)

            guard let floatChannelData = buffer.floatChannelData else { return nil }
            let channelData = floatChannelData[0]
            let totalFrames = Int(buffer.frameLength)

            // Downsample to requested sample count
            let samplesPerBucket = max(totalFrames / sampleCount, 1)
            var waveform: [Float] = []

            for i in 0..<sampleCount {
                let start = i * samplesPerBucket
                let end = min(start + samplesPerBucket, totalFrames)
                guard start < totalFrames else { break }

                var maxAmplitude: Float = 0
                for j in start..<end {
                    let amplitude = abs(channelData[j])
                    if amplitude > maxAmplitude {
                        maxAmplitude = amplitude
                    }
                }
                waveform.append(maxAmplitude)
            }

            // Normalize
            let maxVal = waveform.max() ?? 1.0
            if maxVal > 0 {
                waveform = waveform.map { $0 / maxVal }
            }

            logger.info("Generated waveform with \(waveform.count) samples from \(filePath)")
            return waveform
        } catch {
            logger.error("Waveform generation failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Audio Duration

    func getAudioDuration(filePath: String) async -> TimeInterval? {
        let url = URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds > 0 ? seconds : nil
        } catch {
            return nil
        }
    }

    // MARK: - Audio Info

    func getAudioInfo(filePath: String) -> (sampleRate: Double, channels: Int, duration: TimeInterval)? {
        do {
            let file = try AVAudioFile(forReading: URL(fileURLWithPath: filePath))
            return (file.processingFormat.sampleRate, Int(file.processingFormat.channelCount), TimeInterval(file.length) / file.processingFormat.sampleRate)
        } catch {
            return nil
        }
    }
}

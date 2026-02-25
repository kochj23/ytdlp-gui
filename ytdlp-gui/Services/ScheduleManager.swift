//
//  ScheduleManager.swift
//  ytdlp-gui
//
//  Manages scheduled downloads with timer-based execution
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    @Published var scheduledDownloads: [ScheduledDownload] = []

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "ScheduleManager")
    private var checkTimer: Timer?

    // MARK: - Start / Stop

    func startScheduler() {
        loadSchedules()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processSchedules()
            }
        }
        // Check immediately
        processSchedules()
        logger.info("Scheduler started with \(self.scheduledDownloads.count) scheduled downloads")
    }

    func stopScheduler() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    // MARK: - Schedule Management

    func addSchedule(url: String, options: YTDLPOptions = YTDLPOptions(), date: Date, repeatRule: ScheduledDownload.RepeatRule = .once) {
        let schedule = ScheduledDownload(url: url, options: options, scheduledDate: date, repeatRule: repeatRule)
        scheduledDownloads.append(schedule)
        saveSchedules()
        logger.info("Added scheduled download for \(url) at \(date)")
    }

    func removeSchedule(_ id: UUID) {
        scheduledDownloads.removeAll { $0.id == id }
        saveSchedules()
    }

    func toggleSchedule(_ id: UUID) {
        if let index = scheduledDownloads.firstIndex(where: { $0.id == id }) {
            scheduledDownloads[index].isEnabled.toggle()
            saveSchedules()
        }
    }

    // MARK: - Process

    private func processSchedules() {
        let now = Date()

        for index in scheduledDownloads.indices {
            guard scheduledDownloads[index].isEnabled,
                  scheduledDownloads[index].status == .pending,
                  scheduledDownloads[index].scheduledDate <= now else { continue }

            // Execute the download
            scheduledDownloads[index].status = .running
            let schedule = scheduledDownloads[index]

            DownloadManager.shared.enqueue(url: schedule.url, options: schedule.options, presetName: schedule.presetName)

            scheduledDownloads[index].status = .completed
            scheduledDownloads[index].lastRunDate = now

            // Handle repeating
            if schedule.repeatRule != .once, let nextDate = schedule.nextRunDate {
                var newSchedule = ScheduledDownload(url: schedule.url, options: schedule.options, scheduledDate: nextDate, repeatRule: schedule.repeatRule)
                newSchedule.presetName = schedule.presetName
                scheduledDownloads.append(newSchedule)
            }

            logger.info("Executed scheduled download: \(schedule.url)")
        }

        saveSchedules()
    }

    // MARK: - Persistence

    private var scheduleFile: URL {
        DataStore.shared.appSupportDirectory.appendingPathComponent("schedules.json")
    }

    private func loadSchedules() {
        guard FileManager.default.fileExists(atPath: scheduleFile.path) else { return }
        do {
            let data = try Data(contentsOf: scheduleFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            scheduledDownloads = try decoder.decode([ScheduledDownload].self, from: data)
        } catch {
            logger.error("Failed to load schedules: \(error.localizedDescription)")
        }
    }

    private func saveSchedules() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(scheduledDownloads)
            try data.write(to: scheduleFile, options: .atomic)
        } catch {
            logger.error("Failed to save schedules: \(error.localizedDescription)")
        }
    }

    // MARK: - Computed

    var pendingCount: Int {
        scheduledDownloads.filter { $0.status == .pending && $0.isEnabled }.count
    }

    var nextScheduledDate: Date? {
        scheduledDownloads
            .filter { $0.status == .pending && $0.isEnabled }
            .map(\.scheduledDate)
            .min()
    }
}

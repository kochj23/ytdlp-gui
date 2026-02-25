//
//  ScheduleConfig.swift
//  ytdlp-gui
//
//  Download scheduling model
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct ScheduledDownload: Identifiable, Codable {
    let id: UUID
    var url: String
    var options: YTDLPOptions
    var presetName: String?
    var scheduledDate: Date
    var repeatRule: RepeatRule
    var isEnabled: Bool
    var lastRunDate: Date?
    var status: ScheduleStatus

    init(url: String, options: YTDLPOptions = YTDLPOptions(), scheduledDate: Date, repeatRule: RepeatRule = .once) {
        self.id = UUID()
        self.url = url
        self.options = options
        self.scheduledDate = scheduledDate
        self.repeatRule = repeatRule
        self.isEnabled = true
        self.status = .pending
    }

    enum RepeatRule: String, Codable, CaseIterable {
        case once = "Once"
        case daily = "Daily"
        case weekly = "Weekly"
        case custom = "Custom Interval"
    }

    enum ScheduleStatus: String, Codable {
        case pending = "Pending"
        case running = "Running"
        case completed = "Completed"
        case failed = "Failed"
    }

    var isOverdue: Bool {
        scheduledDate <= Date() && status == .pending && isEnabled
    }

    var nextRunDate: Date? {
        guard repeatRule != .once else { return nil }
        let base = lastRunDate ?? scheduledDate
        switch repeatRule {
        case .daily:
            return Calendar.current.date(byAdding: .day, value: 1, to: base)
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: base)
        case .custom:
            return Calendar.current.date(byAdding: .hour, value: 6, to: base)
        case .once:
            return nil
        }
    }
}

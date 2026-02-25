//
//  CookieImporter.swift
//  ytdlp-gui
//
//  Import cookies from browsers for authenticated downloads
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class CookieImporter: ObservableObject {
    static let shared = CookieImporter()

    @Published var lastImportStatus: String?
    @Published var isImporting = false

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "CookieImporter")

    // MARK: - Import Cookies File

    func importCookiesFile(at path: String) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else {
            lastImportStatus = "File not found: \(path)"
            logger.error("Cookie file not found: \(path)")
            return false
        }

        // Validate it looks like a Netscape cookie file
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            lastImportStatus = "Cannot read file"
            return false
        }

        let isNetscape = contents.hasPrefix("# Netscape HTTP Cookie File") ||
                         contents.hasPrefix("# HTTP Cookie File")

        if !isNetscape {
            logger.warning("Cookie file may not be in Netscape format")
        }

        // Copy to app support directory
        let appSupport = DataStore.shared.appSupportDirectory
        let destPath = appSupport.appendingPathComponent("cookies.txt").path

        do {
            if fm.fileExists(atPath: destPath) {
                try fm.removeItem(atPath: destPath)
            }
            try fm.copyItem(atPath: path, toPath: destPath)
            lastImportStatus = "Cookies imported successfully"
            logger.info("Cookies imported from: \(path)")
            return true
        } catch {
            lastImportStatus = "Import failed: \(error.localizedDescription)"
            logger.error("Cookie import failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Check Browser Cookie Access

    func checkBrowserAccess(browser: CookieSource) -> Bool {
        switch browser {
        case .none:
            return true
        case .chrome:
            return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Google/Chrome/Default/Cookies")
        case .firefox:
            let profilesDir = NSHomeDirectory() + "/Library/Application Support/Firefox/Profiles"
            return FileManager.default.fileExists(atPath: profilesDir)
        case .safari:
            return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Cookies/Cookies.binarycookies")
        case .edge:
            return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Microsoft Edge/Default/Cookies")
        case .brave:
            return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cookies")
        case .opera:
            return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/com.operasoftware.Opera/Cookies")
        case .vivaldi:
            return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Vivaldi/Default/Cookies")
        case .chromium:
            return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Chromium/Default/Cookies")
        case .file:
            return importedCookiePath != nil
        }
    }

    // MARK: - Imported Cookie File Path

    var importedCookiePath: String? {
        let path = DataStore.shared.appSupportDirectory.appendingPathComponent("cookies.txt").path
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }
}

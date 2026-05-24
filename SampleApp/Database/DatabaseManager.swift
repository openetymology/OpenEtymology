//
//  DatabaseManager.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import Foundation
import SQLite

enum DictionaryMode: String, Codable, CaseIterable, Identifiable {
    case encn
    case enen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .encn: return "en-cn"
        case .enen: return "en-en"
        }
    }

    var displayTitle: String {
        title
    }

    var dbFileName: String {
        switch self {
        case .encn: return "wordety_encn_54760_lite"
        case .enen: return "wordety_enen_54700_lite"
        }
    }

    var tableName: String {
        switch self {
        case .encn: return "wordety_encn_54760_v1"
        case .enen: return "wordety_enen_54700_v1"
        }
    }

    var missingEntryMessage: String {
        switch self {
        case .encn:
            return "当前学习内容暂未收录这个单词。"
        case .enen:
            return "This word is not available in the current study content."
        }
    }
}

extension DictionaryMode {
    var usesChineseInterface: Bool {
        self == .encn
    }

    func localized(chinese: String, english: String) -> String {
        usesChineseInterface ? chinese : english
    }
}

final class DictionaryModeManager: ObservableObject {
    static let shared = DictionaryModeManager()

    @Published private(set) var selectedMode: DictionaryMode

    private let storageKey = "wordety_dictionary_mode"

    private init() {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let mode = DictionaryMode(rawValue: raw) {
            selectedMode = mode
        } else {
            selectedMode = .encn
        }
    }

    func updateMode(_ mode: DictionaryMode) {
        guard selectedMode != mode else { return }
        selectedMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: storageKey)
    }
}

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var connections: [DictionaryMode: Connection] = [:]
    private let lock = NSLock()

    private init() { }

    func getConnection(for mode: DictionaryMode) -> Connection? {
        lock.lock()
        defer { lock.unlock() }

        if let existing = connections[mode] {
            return existing
        }

        guard let dbPath = Bundle.main.path(forResource: mode.dbFileName, ofType: "db") else {
            print("❌ 数据库文件未找到: \(mode.dbFileName).db")
            return nil
        }

        do {
            let connection = try Connection(dbPath, readonly: true)
            connections[mode] = connection
            print("✅ 数据库连接成功[\(mode.rawValue)]: \(dbPath)")
            return connection
        } catch {
            print("❌ 无法打开数据库[\(mode.rawValue)]: \(error)")
            return nil
        }
    }

    func getConnection() -> Connection? {
        getConnection(for: DictionaryModeManager.shared.selectedMode)
    }
}

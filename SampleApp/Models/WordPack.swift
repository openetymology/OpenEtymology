//
//  WordPack.swift
//  wordety
//
//  Created by SkyRocket on 2026/01/10.
//

import Foundation
import SwiftUI

/// 单词包模型
struct WordPack: Codable, Identifiable {
    let id: UUID
    var name: String                    // 包名，如 "Book 1", "GRE Core"
    var slugs: [String]                 // 单词列表（存储原型 slug）
    var colorName: String               // 颜色标识
    let createdAt: Date
    var lastUsedAt: Date?
    
    var wordCount: Int { slugs.count }
    
    init(id: UUID = UUID(), name: String, slugs: [String], colorName: String = "purple") {
        self.id = id
        self.name = name
        self.slugs = slugs
        self.colorName = colorName
        self.createdAt = Date()
        self.lastUsedAt = nil
    }
    
    /// 获取对应的 SwiftUI Color
    var color: Color {
        switch colorName {
        case "purple": return AppTheme.jewelPurple
        case "brightPurple": return Color(red: 0.62, green: 0.24, blue: 1.0)
        case "cyan": return AppTheme.jewelCyan
        case "pink": return AppTheme.jewelPink
        case "green": return Color(red: 0.42, green: 0.84, blue: 0.10)
        case "yellow": return AppTheme.jewelYellow
        case "orange": return AppTheme.jewelOrange
        default: return AppTheme.jewelPurple
        }
    }
    
    /// 可选颜色列表
    static let availableColors: [(name: String, color: Color)] = [
        ("purple", AppTheme.jewelPurple),
        ("brightPurple", Color(red: 0.62, green: 0.24, blue: 1.0)),
        ("cyan", AppTheme.jewelCyan),
        ("pink", AppTheme.jewelPink),
        ("green", Color(red: 0.42, green: 0.84, blue: 0.10)),
        ("yellow", AppTheme.jewelYellow),
        ("orange", AppTheme.jewelOrange)
    ]
}

/// 单词来源枚举
enum WordSource: Equatable, Identifiable {
    case searchHistory                  // 搜索历史
    case wordPack(UUID)                 // 指定的单词包
    
    var id: String {
        switch self {
        case .searchHistory:
            return "history"
        case .wordPack(let uuid):
            return uuid.uuidString
        }
    }
}

//
//  Example.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import Foundation

struct Example: Codable, Identifiable {
    let id = UUID()
    let en: String  // 英文例句
    let zh: String  // 中文翻译
}

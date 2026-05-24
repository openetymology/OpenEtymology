//
//  Definition.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import Foundation

struct Definition: Codable, Identifiable {
    let id = UUID()
    let pos: String      // 词性
    let meaning: String  // 释义
}

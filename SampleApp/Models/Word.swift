//
//  Word.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import Foundation

struct Word: Codable, Identifiable {
    let id: String  // 对应数据库的 word 字段
    let slug: String
    let pronUk: String?
    let pronUs: String?
    let definitions: [Definition]
    let examples: [Example]
    let morphemes: [Morpheme]
    let etymologyOrigin: String?
    let etymologyAnalysis: String?
}

extension Word {
    var wordForDisplay: String {
        id.isEmpty ? slug : id
    }
}

extension String {
    var cleanedDisplayText: String {
        replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var preservingLineDisplayText: String {
        components(separatedBy: .newlines)
            .map {
                $0.replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

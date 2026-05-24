//
//  Morpheme.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import Foundation

struct Morpheme: Codable, Identifiable {
    let id = UUID()
    let piece: String
    let gloss: String
    let lang: String?
    let position: Int
    let canReconstruct: Bool
}

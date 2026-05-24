//
//  HistoryPDFExporter.swift
//  wordety
//
//  Created by Codex on 2026/05/11.
//

import Foundation
import UIKit

enum HistoryPDFExportError: LocalizedError {
    case plusRequired
    case noWords

    var errorDescription: String? {
        switch self {
        case .plusRequired:
            return "OpenEtymology Plus is required to create personal study notes."
        case .noWords:
            return "There are no valid history words for study notes."
        }
    }
}

final class HistoryPDFExporter {
    private let repository = WordRepository()

    func exportHistory(slugs: [String], mode: DictionaryMode) throws -> URL {
        guard PlusAccessManager.shared.canExportHistoryPDF else {
            throw HistoryPDFExportError.plusRequired
        }

        let exportSlugs = Array(slugs.prefix(PlusAccessManager.historyPDFExportLimit))
        let words = exportSlugs.compactMap { repository.getWordBySlug($0.lowercased(), mode: mode) }
        guard !words.isEmpty else {
            throw HistoryPDFExportError.noWords
        }

        let timestamp = Self.fileTimestampFormatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenEtymology-Study-Notes-\(timestamp).pdf")

        try? FileManager.default.removeItem(at: url)
        try render(words: words, mode: mode, to: url)
        return url
    }

    private func render(words: [Word], mode: DictionaryMode, to url: URL) throws {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 44
        let contentWidth = pageRect.width - margin * 2
        let bottomLimit = pageRect.height - margin

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: url) { context in
            var y = margin

            func beginPageIfNeeded(requiredHeight: CGFloat) {
                if y + requiredHeight > bottomLimit {
                    context.beginPage()
                    y = margin
                }
            }

            context.beginPage()
            y += drawText(
                mode.localized(
                    chinese: "OpenEtymology 个人学习笔记",
                    english: "OpenEtymology Personal Study Notes"
                ),
                in: CGRect(x: margin, y: y, width: contentWidth, height: 60),
                attributes: Self.titleAttributes
            ) + 6

            y += drawText(
                mode.localized(
                    chinese: "由本机搜索历史生成，仅供个人英语学习与复习使用。",
                    english: "Generated locally from your own search history for personal vocabulary study."
                ),
                in: CGRect(x: margin, y: y, width: contentWidth, height: 40),
                attributes: Self.subtitleAttributes
            ) + 10

            y += drawText(
                mode.localized(
                    chinese: "这不是图书、期刊、新闻、在线出版物或公开分发的词典内容。",
                    english: "This is not a book, magazine, news product, online publication, or publicly distributed dictionary content."
                ),
                in: CGRect(x: margin, y: y, width: contentWidth, height: 44),
                attributes: Self.noteAttributes
            ) + 24

            for (index, word) in words.enumerated() {
                beginPageIfNeeded(requiredHeight: 150)

                let wordTitle = "\(index + 1). \(word.wordForDisplay)"
                y += drawText(
                    wordTitle,
                    in: CGRect(x: margin, y: y, width: contentWidth, height: 44),
                    attributes: Self.wordAttributes
                ) + 8

                let definitionText = formattedDefinitions(for: word)
                let definitionTextHeight = textHeight(definitionText, width: contentWidth, attributes: Self.bodyAttributes)
                beginPageIfNeeded(requiredHeight: 20 + 4 + definitionTextHeight + 12)

                y += drawLabel(mode.localized(chinese: "释义", english: "Meaning"), x: margin, y: y, width: contentWidth) + 4
                let definitionHeight = drawWrappedText(
                    definitionText,
                    x: margin,
                    y: y,
                    width: contentWidth,
                    attributes: Self.bodyAttributes
                )
                y += definitionHeight + 12

                let structureText = formattedStructure(for: word)
                let structureTextHeight = textHeight(structureText, width: contentWidth, attributes: Self.bodyAttributes)
                beginPageIfNeeded(requiredHeight: 20 + 4 + structureTextHeight + 40)

                y += drawLabel(mode.localized(chinese: "构词结构", english: "Word Structure"), x: margin, y: y, width: contentWidth) + 4
                let structureHeight = drawWrappedText(
                    structureText,
                    x: margin,
                    y: y,
                    width: contentWidth,
                    attributes: Self.bodyAttributes
                )
                y += structureHeight + 20

                drawDivider(x: margin, y: y, width: contentWidth)
                y += 20
            }
        }
    }

    private func formattedDefinitions(for word: Word) -> String {
        let definitions = word.definitions.prefix(2).map { definition in
            let pos = definition.pos.cleanedDisplayText
            let meaning = definition.meaning.cleanedDisplayText
            return pos.isEmpty ? meaning : "\(pos). \(meaning)"
        }

        return definitions.isEmpty ? "—" : definitions.joined(separator: "\n")
    }

    private func formattedStructure(for word: Word) -> String {
        guard !word.morphemes.isEmpty else { return "—" }

        return word.morphemes
            .sorted { $0.position < $1.position }
            .map { morpheme in
                let piece = morpheme.piece.cleanedDisplayText
                let gloss = morpheme.gloss.cleanedDisplayText
                return gloss.isEmpty ? piece : "\(piece) <\(gloss)>"
            }
            .joined(separator: " + ")
    }

    @discardableResult
    private func drawLabel(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        drawText(
            text.uppercased(),
            in: CGRect(x: x, y: y, width: width, height: 20),
            attributes: Self.labelAttributes
        )
    }

    private func drawDivider(x: CGFloat, y: CGFloat, width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))
        UIColor(red: 0.86, green: 0.88, blue: 0.91, alpha: 1).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    @discardableResult
    private func drawText(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let height = textHeight(text, width: rect.width, attributes: attributes)
        (text as NSString).draw(
            with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return height
    }

    @discardableResult
    private func drawWrappedText(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        attributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        drawText(text, in: CGRect(x: x, y: y, width: width, height: .greatestFiniteMagnitude), attributes: attributes)
    }

    private func textHeight(_ text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(rect.height)
    }

    private static let fileTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    private static let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 28, weight: .bold),
        .foregroundColor: UIColor(red: 0.07, green: 0.12, blue: 0.20, alpha: 1)
    ]

    private static let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: UIColor(red: 0.38, green: 0.44, blue: 0.52, alpha: 1)
    ]

    private static let noteAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .medium),
        .foregroundColor: UIColor(red: 0.48, green: 0.54, blue: 0.62, alpha: 1)
    ]

    private static let wordAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 22, weight: .bold),
        .foregroundColor: UIColor(red: 0.08, green: 0.61, blue: 0.96, alpha: 1)
    ]

    private static let labelAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9, weight: .black),
        .foregroundColor: UIColor(red: 0.86, green: 0.10, blue: 0.51, alpha: 1),
        .kern: 1.2
    ]

    private static let bodyAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 13, weight: .regular),
        .foregroundColor: UIColor(red: 0.16, green: 0.20, blue: 0.28, alpha: 1)
    ]
}

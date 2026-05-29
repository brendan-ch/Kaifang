//
//  PronunciationProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import Foundation

/// Looks up the pronunciation of a Chinese word from a CC-CEDICT dictionary.
///
/// The dictionary text is parsed lazily on the first lookup and cached in
/// memory, keyed by both simplified and traditional headwords. Pronunciations
/// are stored as CC-CEDICT's numbered pinyin — the form every other notation
/// (tone-mark pinyin, zhuyin) is derived from.
public actor PronunciationProvider {

    /// Supplies the raw CC-CEDICT text. The seam lets tests inject a small
    /// excerpt instead of the bundled dictionary.
    public protocol DictionarySource: Sendable {
        func loadText() async throws -> String
    }

    private let source: any DictionarySource
    private var index: [String: [Pronunciation]]?

    public init() {
        self.source = BundledCEDICTSource()
    }

    init(source: any DictionarySource) {
        self.source = source
    }

    public func pronunciations(
        for word: String,
        system: System = .numberedPinyin
    ) async throws -> [Pronunciation] {
        guard system == .numberedPinyin else {
            throw Error.unsupportedSystem(system)
        }
        return try await loadedIndex()[word] ?? []
    }

    private func loadedIndex() async throws -> [String: [Pronunciation]] {
        if let index { return index }
        let built = Self.buildIndex(from: try await source.loadText())
        index = built
        return built
    }

    /// Parses CC-CEDICT text into a headword → pronunciations map, keyed by both
    /// the simplified and traditional forms. Glosses are discarded.
    static func buildIndex(from text: String) -> [String: [Pronunciation]] {
        var index: [String: [Pronunciation]] = [:]
        // `isNewline` handles LF, CR, and CRLF — CC-CEDICT ships CRLF, and Swift
        // treats "\r\n" as a single Character, so splitting on "\n" alone fails.
        for line in text.split(whereSeparator: \.isNewline) {
            guard let entry = parseLine(line) else { continue }
            index[entry.simplified, default: []].append(entry)
            if entry.traditional != entry.simplified {
                index[entry.traditional, default: []].append(entry)
            }
        }
        return index
    }

    /// Parses a single `TRAD SIMP [pin1 yin1] /gloss/...` line, returning `nil`
    /// for comment, metadata, and malformed lines.
    private static func parseLine(_ line: Substring) -> Pronunciation? {
        guard let first = line.first, first != "#" else { return nil }
        guard let open = line.firstIndex(of: "["),
              let close = line[open...].firstIndex(of: "]") else { return nil }
        let headwords = line[..<open].split(separator: " ", omittingEmptySubsequences: true)
        guard headwords.count >= 2 else { return nil }
        return Pronunciation(
            simplified: String(headwords[1]),
            traditional: String(headwords[0]),
            system: .numberedPinyin,
            value: String(line[line.index(after: open)..<close])
        )
    }

    private struct BundledCEDICTSource: DictionarySource {
        func loadText() async throws -> String {
            guard let url = Bundle.module.url(forResource: "cedict_ts", withExtension: "u8") else {
                throw Error.resourceUnavailable
            }
            return try String(contentsOf: url, encoding: .utf8)
        }
    }
}

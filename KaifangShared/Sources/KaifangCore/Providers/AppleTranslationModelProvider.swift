//
//  AppleTranslationModelProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation
#if canImport(Translation)
import Translation
#endif
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Translates using Apple's on-device Translation framework. When Apple
/// Intelligence is available and the query carries surrounding context, the
/// provider translates the *context* and uses a `TranslationRefiner` to
/// extract the specific translation of the original word or phrase from it.
///
/// The provider is split into two injectable seams (`SystemTranslator` and
/// `TranslationRefiner`) so the orchestration can be unit-tested with fakes —
/// the Apple system types themselves aren't directly mockable.
@available(iOS 26.0, macOS 26.0, *)
public final class AppleTranslationModelProvider: TranslationModel.Provider {

    // MARK: Types

    public protocol SystemTranslator: Sendable {
        func translate(
            _ text: String,
            from source: Locale.Language,
            to target: Locale.Language
        ) async throws -> String
    }

    public protocol TranslationRefiner: Sendable {
        var isAvailable: Bool { get }

        /// Given a passage translated into `targetLang`, extract only the
        /// translation of `originalText` as it appears in that passage.
        func extractTranslation(
            of originalText: String,
            translatedContext: String,
            originalContext: String,
            targetLang: Locale.Language
        ) async throws -> String
    }

    public enum Error: LocalizedError {
        case notImplemented(String)
        case translationUnavailable
        
        var localizedDescription: String {
            switch self {
            case .translationUnavailable:
                "Translation is currently unavailable. Please try again later or use a different provider."
            case .notImplemented(_):
                "A method was not implemented."
            }
        }
    }

    // MARK: State

    private let translator: any SystemTranslator
    private let refiner: (any TranslationRefiner)?

    // MARK: Init

    public convenience init() {
        self.init(translator: nil, refiner: nil)
    }

    init(
        translator: (any SystemTranslator)? = nil,
        refiner: (any TranslationRefiner)? = nil
    ) {
        self.translator = translator ?? AppleSystemTranslator()
        self.refiner = refiner ?? AppleFoundationModelsRefiner()
    }

    // MARK: Translate

    public func translate(_ query: TranslationProvider.LookupArguments) async throws -> TranslationProvider.Translation {
        let finalText: String

        if let refiner, refiner.isAvailable,
           let context = query.originalTextContext, !context.isEmpty {
            let translatedContext = try await translator.translate(
                context,
                from: query.originalTextLang,
                to: query.translatedTextLang
            )
            do {
                finalText = try await refiner.extractTranslation(
                    of: query.originalText,
                    translatedContext: translatedContext,
                    originalContext: context,
                    targetLang: query.translatedTextLang
                )
            } catch {
                // Extraction is best-effort — fall back to translating the
                // original text directly rather than failing the whole call.
                finalText = try await translator.translate(
                    query.originalText,
                    from: query.originalTextLang,
                    to: query.translatedTextLang
                )
            }
        } else {
            finalText = try await translator.translate(
                query.originalText,
                from: query.originalTextLang,
                to: query.translatedTextLang
            )
        }

        return TranslationProvider.Translation(
            id: UUID(),
            originalText: query.originalText,
            originalTextLang: query.originalTextLang,
            originalTextContext: query.originalTextContext,
            translatedText: finalText,
            translatedTextLang: query.translatedTextLang
        )
    }

    // MARK: Production helpers

    private struct AppleSystemTranslator: SystemTranslator {
        func translate(
            _ text: String,
            from source: Locale.Language,
            to target: Locale.Language
        ) async throws -> String {
            let availability = LanguageAvailability()
            let status = await availability.status(from: source, to: target)

            if status == .unsupported {
                throw Error.translationUnavailable
            }

            let session = TranslationSession(installedSource: source, target: target)
            try await session.prepareTranslation()

            let response = try await session.translate(text)
            return response.targetText
        }
    }

    private struct AppleFoundationModelsRefiner: TranslationRefiner {
        var isAvailable: Bool {
            SystemLanguageModel.default.isAvailable
        }

        func extractTranslation(
            of originalText: String,
            translatedContext: String,
            originalContext: String,
            targetLang: Locale.Language
        ) async throws -> String {
            let instructions = """
            You extract the translation of a specific phrase from a \
            translated passage. You will be given the original word, the original \
            context where it appears, and the translated context. Identify the \
            translation of the original word as it appears in the translated \
            context, and return only that translation. Do not add commentary, \
            quotation marks, or explanation.
            """

            let session = LanguageModelSession(instructions: instructions)

            let targetLabel = targetLang.languageCode?.identifier ?? "the target language"
            let prompt = """
            Original word or phrase:
            \(originalText)

            Original context:
            \(originalContext)

            Translated context in \(targetLabel):
            \(translatedContext)

            Return only the translation of the original word or phrase.
            """

            let response = try await session.respond(to: prompt)
            return response.content
        }
    }
}

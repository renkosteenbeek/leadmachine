import Foundation
import FoundationModels

class TextEvaluator {
    private let session: LanguageModelSession

    init() {
        self.session = LanguageModelSession(
            instructions: {
                "Je bent een professionele tekst beoordelaar die constructieve feedback geeft."
            }
        )
    }

    func evaluateQuality(_ text: String) async throws -> String {
        let prompt = """
        Beoordeel deze tekst op kwaliteit (1-10) en geef kort advies:
        "\(text)"

        Format: Score: X/10 - [advies]
        """
        let result = try await session.respond(to: prompt)
        return result.content
    }

    func analyzeSentiment(_ text: String) async throws -> String {
        let options = GenerationOptions(temperature: 0.3)
        let result = try await session.respond(
            to: "Geef het sentiment (POSITIEF/NEGATIEF/NEUTRAAL): \(text)",
            options: options
        )
        return result.content
    }

    func checkAppropriate(_ text: String) async throws -> Bool {
        let prompt = """
        Is deze content geschikt? Antwoord alleen JA of NEE:
        "\(text)"
        """
        let result = try await session.respond(to: prompt)
        return result.content.uppercased().contains("JA")
    }

    func evaluateDetailed(_ text: String) async throws -> DetailedEvaluation {
        let result = try await session.respond(
            to: """
            Geef een gedetailleerde evaluatie van deze tekst:
            "\(text)"

            Geef een score (0.0-10.0), sentiment (positief/negatief/neutraal),
            categorie (professioneel/informeel/technisch),
            sterke punten en verbeterpunten.
            """,
            generating: DetailedEvaluation.self,
            includeSchemaInPrompt: true
        )
        return result.content
    }

    func streamAnalysis(_ text: String) async throws {
        let stream = try await session.streamResponse {
            "Geef een uitgebreide analyse: \(text)"
        }

        print("Streaming analyse:\n")
        for try await chunk in stream {
            print(chunk.content, terminator: "")
            fflush(stdout)
        }
        print("\n")
    }
}

import Foundation
import FoundationModels
import Logging

@available(macOS 26.0, *)
actor CPQLeadAnalyzer {
    private let logger = Logger(label: "com.leadmachine.analyzer")
    private let session: LanguageModelSession

    init() throws {
        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            throw AnalyzerError.modelUnavailable
        }

        session = LanguageModelSession(instructions: {
            """
            Je bent een AI assistent die helpt met het identificeren van potentiële CPQ (Configure, Price, Quote) implementatie leads.

            CPQ systemen worden gebruikt door bedrijven voor:
            - Complexe productconfiguraties
            - Prijsberekeningen met regels en kortingen
            - Offerte generatie
            - Sales automation

            Typische CPQ leads zijn bedrijven die:
            - Complexe producten/diensten verkopen
            - Maatwerk configuraties nodig hebben
            - Veel varianten en opties hebben
            - Prijsregels en kortingsstructuren gebruiken
            - Hun sales proces willen automatiseren
            - ERP integratie nodig hebben

            Geef altijd een duidelijk JA of NEE antwoord met een korte, concrete toelichting.
            """
        })

        logger.info("CPQ Lead Analyzer initialized")
    }

    func analyze(message: Message) async throws -> CPQLeadDecision {
        let prompt = buildPrompt(for: message)

        logger.info("Analyzing email: \(message.subject)")

        let options = GenerationOptions(
            sampling: .greedy,
            temperature: 0.3,
            maximumResponseTokens: 300
        )

        let result = try await session.respond(
            to: prompt,
            generating: CPQLeadDecision.self,
            includeSchemaInPrompt: true,
            options: options
        )

        logger.info("Analysis result: isLead=\(result.content.isLead)")

        return result.content
    }

    private func buildPrompt(for message: Message) -> String {
        let fromAddress = message.from.emailAddress.address
        let bodyText = message.bodyPreview

        return """
        Analyseer deze email en bepaal of dit een potentieel interessante lead is voor een CPQ implementatie.

        Van: \(fromAddress)
        Onderwerp: \(message.subject)

        Inhoud (preview):
        \(bodyText)

        Geef een analyse in het volgende formaat:
        - isLead: true of false
        - reasoning: Een korte, concrete toelichting (max 2-3 zinnen) waarom dit wel of niet een CPQ lead is

        Let specifiek op:
        - Bedrijven die ERP, CRM, of sales automation zoeken
        - Vermeldingen van complexe producten of configuraties
        - Vragen over prijsberekeningen of offertes
        - B2B context met maatwerk oplossingen
        """
    }
}

enum AnalyzerError: Error, CustomStringConvertible {
    case modelUnavailable

    var description: String {
        switch self {
        case .modelUnavailable:
            return "Apple Language Model is not available. Requires macOS 15+ with Apple Intelligence enabled."
        }
    }
}

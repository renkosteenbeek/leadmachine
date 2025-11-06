import Foundation
import OpenAI
import Logging

actor CPQLeadAnalyzer {
    private let logger = Logger(label: "com.leadmachine.analyzer")
    private let openAI: OpenAI

    init(apiKey: String) {
        self.openAI = OpenAI(apiToken: apiKey)
        logger.info("CPQ Lead Analyzer initialized (OpenAI GPT-5)")
    }

    func analyze(message: Message) async throws -> CPQLeadDecision {
        let prompt = buildPrompt(for: message)

        logger.info("Analyzing email: \(message.subject)")

        let systemPrompt = """
        Je bent een lead kwalificatie expert voor HiveCPQ - een CPQ/product configurator platform voor manufacturing bedrijven.

        HiveCPQ is geschikt voor producenten met complexe producten die online configuratie, prijsberekening en offertes willen automatiseren.

        ✅ Goede leads:
        - Manufacturing bedrijven die portals, configurators of productconfiguratiesystemen zoeken
        - Producenten met varianten, opties of maatwerk in hun producten
        - Bedrijven die klanten/dealers online hun producten willen laten configureren

        ❌ Geen leads:
        - Distributeurs, handelsbedrijven of dienstverleners (geen eigen productie)
        - Standaard CRM/ERP/WMS zonder configuratie-aspect
        - Eenvoudige producten zonder varianten of complexiteit
        - Spam en notificaties

        Beoordeel of deze email een potentiële HiveCPQ lead is. Wees kritisch: alleen bedrijven die echt configuratie/portal functionaliteit nodig hebben zijn interessant.

        Geef een JSON response:
        {
          "isLead": true/false,
          "reasoning": "waarom wel/niet relevant (2-4 zinnen)",
          "summary": "samenvatting als STRING met newlines (\\n) tussen bullet points. Formaat:\\n- Bedrijf: ...\\n- Sector: ...\\n- Budget: ...\\n- Behoeftes: ..."
        }
        """

        let systemMessage = ChatQuery.ChatCompletionMessageParam.system(
            .init(content: .textContent(systemPrompt))
        )
        let userMessage = ChatQuery.ChatCompletionMessageParam.user(
            .init(content: .string(prompt))
        )

        let query = ChatQuery(
            messages: [systemMessage, userMessage],
            model: .gpt5,
            responseFormat: .jsonObject
        )

        let result = try await openAI.chats(query: query)

        guard let choice = result.choices.first,
              let content = choice.message.content else {
            throw AnalyzerError.invalidResponse
        }

        guard let jsonData = content.data(using: .utf8) else {
            throw AnalyzerError.invalidResponse
        }

        let decoder = JSONDecoder()
        let decision = try decoder.decode(CPQLeadDecision.self, from: jsonData)

        logger.info("Analysis result: isLead=\(decision.isLead)")

        return decision
    }

    private func buildPrompt(for message: Message) -> String {
        let fromAddress = message.from.emailAddress.address

        let bodyText: String
        if let body = message.body?.content {
            bodyText = cleanAndTruncateBody(body, maxChars: 4000)
        } else {
            bodyText = cleanAndTruncateBody(message.bodyPreview, maxChars: 2000)
        }

        return """
        Van: \(fromAddress)
        Onderwerp: \(message.subject)

        \(bodyText)

        Is dit een potentiële HiveCPQ lead?
        """
    }

    private func cleanAndTruncateBody(_ body: String, maxChars: Int) -> String {
        var cleaned = body

        cleaned = stripHTML(cleaned)

        cleaned = cleaned
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        if cleaned.count > maxChars {
            let truncated = String(cleaned.prefix(maxChars))
            return truncated + "\n\n[...]"
        }

        return cleaned
    }

    private func stripHTML(_ html: String) -> String {
        var text = html

        text = text.replacingOccurrences(of: "<style[^>]*>.*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<!--.*?-->", with: "", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<head[^>]*>.*?</head>", with: "", options: [.regularExpression, .caseInsensitive])

        text = text.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<p[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "</p>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<div[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: [.regularExpression, .caseInsensitive])

        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        text = text.replacingOccurrences(of: "&nbsp;", with: " ", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&lt;", with: "<", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&gt;", with: ">", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&amp;", with: "&", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&quot;", with: "\"", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&#39;", with: "'", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&apos;", with: "'", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&#\\d+;", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "&[a-zA-Z]+;", with: " ", options: .regularExpression)

        return text
    }
}

enum AnalyzerError: Error, CustomStringConvertible {
    case invalidResponse

    var description: String {
        switch self {
        case .invalidResponse:
            return "OpenAI API returned invalid response"
        }
    }
}

import Foundation
import FoundationModels

@main
struct AppleFMTest {
    static func main() async {
        print("🍎 Apple Foundation Models - Tekst Beoordeling Test\n")
        print("=" + String(repeating: "=", count: 50) + "\n")

        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            print("❌ Foundation Models niet beschikbaar op dit systeem")
            print("   Vereist: macOS 26+ met Apple Intelligence ingeschakeld")
            return
        }

        print("✅ Foundation Models beschikbaar\n")

        await testTextQualityEvaluation()
        await testSentimentAnalysis()
        await testContentModeration()
        await testStructuredEvaluation()
        await testStreamingEvaluation()

        print("\n" + String(repeating: "=", count: 52))
        print("✅ Alle tests voltooid!")
    }

    static func testTextQualityEvaluation() async {
        print("📝 Test 1: Tekstkwaliteit Beoordeling")
        print(String(repeating: "-", count: 52))

        let session = LanguageModelSession()

        let testTexts = [
            "De zon schijnt mooi vandaag en de vogels zingen.",
            "dit is slecht geschreven tekst zonder hoofdletters en leestekens",
            "In deze uitgebreide analyse behandelen we de economische impact van duurzame energie op de Europese markt."
        ]

        for (index, text) in testTexts.enumerated() {
            print("\nTekst \(index + 1): \"\(text)\"")

            let prompt = """
            Beoordeel de volgende tekst op kwaliteit (schaal 1-10) en geef kort advies:

            "\(text)"

            Geef alleen een score (1-10) en een korte beoordeling in 1-2 zinnen.
            """

            do {
                let result = try await session.respond(to: prompt)
                print("Beoordeling: \(result.content)")
            } catch {
                print("❌ Error: \(error)")
            }
        }
        print()
    }

    static func testSentimentAnalysis() async {
        print("😊 Test 2: Sentiment Analyse")
        print(String(repeating: "-", count: 52))

        let session = LanguageModelSession(
            instructions: {
                "Je bent een sentiment analyser. Beoordeel teksten als POSITIEF, NEGATIEF, of NEUTRAAL."
            }
        )

        let sentimentTexts = [
            "Ik ben super blij met dit product! Absoluut fantastisch!",
            "Dit is de slechtste ervaring die ik ooit heb gehad.",
            "Het product kwam aan op dinsdag."
        ]

        for text in sentimentTexts {
            print("\nTekst: \"\(text)\"")

            do {
                let result = try await session.respond(
                    to: "Sentiment: \(text)",
                    options: GenerationOptions(temperature: 0.3)
                )
                print("Sentiment: \(result.content)")
            } catch {
                print("❌ Error: \(error)")
            }
        }
        print()
    }

    static func testContentModeration() async {
        print("🛡️  Test 3: Content Moderatie")
        print(String(repeating: "-", count: 52))

        let session = LanguageModelSession()

        let contents = [
            "Wat een mooie dag om te gaan wandelen in het park.",
            "Ik vind dit een zeer nuttige tutorial voor beginners.",
            "spam spam goedkope aanbieding klik hier nu!!!"
        ]

        for content in contents {
            print("\nContent: \"\(content)\"")

            let prompt = """
            Beoordeel of deze content geschikt is (JA/NEE) en waarom:
            "\(content)"

            Geef alleen: GESCHIKT: [JA/NEE] - [reden in 1 zin]
            """

            do {
                let result = try await session.respond(to: prompt)
                print("Moderatie: \(result.content)")
            } catch {
                print("❌ Error: \(error)")
            }
        }
        print()
    }

    static func testStructuredEvaluation() async {
        print("📊 Test 4: Gestructureerde Evaluatie met @Generable")
        print(String(repeating: "-", count: 52))

        let session = LanguageModelSession()

        let text = "Deze tekst is zorgvuldig geschreven met aandacht voor detail en bevat waardevolle informatie."

        print("\nTekst: \"\(text)\"")

        do {
            let result = try await session.respond(
                to: """
                Evalueer deze tekst en geef een score (0.0-10.0),
                categorie (professioneel/informeel/technisch),
                en feedback:

                "\(text)"
                """,
                generating: TextEvaluation.self,
                includeSchemaInPrompt: true
            )

            print("\n📊 Gestructureerde Evaluatie:")
            print("   Score: \(result.content.score)/10.0")
            print("   Categorie: \(result.content.category)")
            print("   Feedback: \(result.content.feedback)")
        } catch {
            print("❌ Error: \(error)")
        }
        print()
    }

    static func testStreamingEvaluation() async {
        print("⚡ Test 5: Streaming Evaluatie")
        print(String(repeating: "-", count: 52))

        let session = LanguageModelSession()

        let longText = """
        Kunstmatige intelligentie transformeert de moderne technologie-industrie.
        Machine learning algoritmes worden steeds geavanceerder en kunnen complexe
        patronen herkennen in grote datasets. Deze ontwikkelingen hebben impact op
        vele sectoren, van gezondheidszorg tot financiële dienstverlening.
        """

        let preview = String(longText.prefix(80))
        print("\nTekst: \"\(preview.trimmingCharacters(in: .whitespaces))...\"")
        print("\nStreaming analyse:\n")

        do {
            let stream = try await session.streamResponse {
                "Geef een uitgebreide analyse van deze tekst: \(longText)"
            }

            for try await chunk in stream {
                print(chunk.content, terminator: "")
                fflush(stdout)
            }
            print("\n")
        } catch {
            print("❌ Error: \(error)")
        }
        print()
    }
}

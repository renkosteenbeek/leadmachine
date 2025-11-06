#!/usr/bin/env swift

import Foundation
import FoundationModels

print("🍎 Apple Foundation Models - Simpel Voorbeeld\n")

let model = SystemLanguageModel.default
guard case .available = model.availability else {
    print("❌ Foundation Models niet beschikbaar")
    exit(1)
}

let session = LanguageModelSession()

let testTekst = "Dit is een geweldige tutorial over Swift programmeren!"

print("Tekst: \"\(testTekst)\"\n")

Task {
    do {
        let kwaliteit = try await session.respond(
            to: "Beoordeel deze tekst kort op kwaliteit (1-10): \(testTekst)"
        )
        print("📊 Kwaliteit: \(kwaliteit.content)\n")

        let sentiment = try await session.respond(
            to: "Geef het sentiment (POSITIEF/NEGATIEF/NEUTRAAL): \(testTekst)",
            options: GenerationOptions(temperature: 0.3)
        )
        print("😊 Sentiment: \(sentiment.content)\n")

        print("✅ Klaar!")
    } catch {
        print("❌ Error: \(error)")
    }

    exit(0)
}

RunLoop.main.run()

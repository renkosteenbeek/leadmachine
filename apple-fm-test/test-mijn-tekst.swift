#!/usr/bin/env swift

import Foundation
import FoundationModels

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Gebruik: swift test-mijn-tekst.swift \"je tekst hier\"")
    exit(1)
}

let mijnTekst = args[1]

print("🔍 Beoordelingen van jouw tekst:\n")
print("📝 Tekst: \"\(mijnTekst)\"\n")

let model = SystemLanguageModel.default
guard case .available = model.availability else {
    print("❌ Foundation Models niet beschikbaar")
    exit(1)
}

let session = LanguageModelSession()

Task {
    do {
        print("⏳ Aan het analyseren...\n")

        let kwaliteit = try await session.respond(
            to: "Beoordeel deze tekst op kwaliteit (1-10) met kort advies: \(mijnTekst)"
        )
        print("📊 Kwaliteit:\n   \(kwaliteit.content)\n")

        let sentiment = try await session.respond(
            to: "Geef het sentiment (POSITIEF/NEGATIEF/NEUTRAAL) met korte uitleg: \(mijnTekst)",
            options: GenerationOptions(temperature: 0.3)
        )
        print("😊 Sentiment:\n   \(sentiment.content)\n")

        let verbeter = try await session.respond(
            to: "Geef 2-3 concrete tips om deze tekst te verbeteren: \(mijnTekst)"
        )
        print("💡 Verbeter Tips:\n   \(verbeter.content)\n")

        print("✅ Analyse compleet!")
    } catch {
        print("❌ Error: \(error)")
    }

    exit(0)
}

RunLoop.main.run()

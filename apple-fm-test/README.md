# Apple Foundation Models - Tekst Beoordeling

Test project voor Apple's Foundation Models framework op macOS 26.

## Vereisten

- macOS 26 (Sequoia 15.2+)
- Apple Intelligence ingeschakeld
- Swift 6.2+
- Apparaat met Apple Intelligence support (M1/M2/M3/M4)

## Wat is Foundation Models?

Apple's Foundation Models framework geeft toegang tot het on-device 3B parameter AI model. Het draait volledig lokaal op je Mac voor privacy en snelheid.

## Features in dit project

### 1. Tekstkwaliteit Beoordeling
Beoordeelt teksten op grammatica, stijl en leesbaarheid met een score van 1-10.

### 2. Sentiment Analyse
Bepaalt of een tekst positief, negatief of neutraal is.

### 3. Content Moderatie
Controleert of content geschikt is en geeft redenen.

### 4. Gestructureerde Evaluatie
Gebruikt `@Generable` voor type-safe JSON output met scores, categorieën en feedback.

### 5. Streaming Evaluatie
Real-time analyse met streaming responses voor lange teksten.

## Gebruik

### Build en run het demo project:

```bash
cd apple-fm-test
swift run
```

### Gebruik de TextEvaluator class in je eigen code:

```swift
import FoundationModels

let evaluator = TextEvaluator()

let quality = try await evaluator.evaluateQuality("Je tekst hier")
print(quality)

let sentiment = try await evaluator.analyzeSentiment("Geweldige dag!")
print(sentiment)

let isOK = try await evaluator.checkAppropriate("Content hier")
print(isOK ? "✅ Geschikt" : "❌ Niet geschikt")

let detailed = try await evaluator.evaluateDetailed("Tekst")
print("Score: \(detailed.score)")
print("Sentiment: \(detailed.sentiment)")
print("Categorie: \(detailed.category)")
```

## API Beschikbaarheid Checken

```swift
let model = SystemLanguageModel.default

switch model.availability {
case .available:
    print("✅ Model beschikbaar")
case .unavailable(let reason):
    print("❌ Niet beschikbaar: \(reason)")
}
```

## Belangrijke Opties

### Temperature
- `0.0-0.3`: Consistente, voorspelbare output (goed voor classificatie)
- `0.7-1.0`: Creatieve, gevarieerde output (goed voor tekst generatie)

### GenerationOptions

```swift
let options = GenerationOptions(
    sampling: .greedy,
    temperature: 0.3,
    maximumResponseTokens: 200
)
```

## Bronnen

- [Apple Developer Docs](https://developer.apple.com/documentation/FoundationModels)
- [WWDC25 Video: Meet Foundation Models](https://developer.apple.com/videos/play/wwdc2025/286/)
- [createwithswift.com Tutorial](https://www.createwithswift.com/exploring-the-foundation-models-framework/)

## Privacy

Alle verwerking gebeurt on-device. Data verlaat je Mac niet.

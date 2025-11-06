import Foundation
import FoundationModels

@Generable
struct TextEvaluation: Equatable {
    let score: Double
    let category: String
    let feedback: String
}

@Generable
struct DetailedEvaluation: Equatable {
    let score: Double
    let sentiment: String
    let category: String
    let strengths: String
    let improvements: String
}

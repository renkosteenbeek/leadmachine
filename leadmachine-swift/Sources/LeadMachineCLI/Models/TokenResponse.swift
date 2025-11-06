import Foundation

struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct TokenCache {
    var token: String
    var expiresAt: Date

    var isValid: Bool {
        Date() < expiresAt.addingTimeInterval(-300)
    }
}

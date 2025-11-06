import Foundation

actor Authenticator {
    private let config: Config
    private var tokenCache: TokenCache?

    init(config: Config) {
        self.config = config
    }

    func getAccessToken() async throws -> String {
        if let cache = tokenCache, cache.isValid {
            return cache.token
        }

        let url = URL(string: "https://login.microsoftonline.com/\(config.tenantId)/oauth2/v2.0/token")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "scope": "https://graph.microsoft.com/.default",
            "grant_type": "client_credentials"
        ]

        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AuthError.authenticationFailed(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(TokenResponse.self, from: data)

        let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        tokenCache = TokenCache(token: tokenResponse.accessToken, expiresAt: expiresAt)

        return tokenResponse.accessToken
    }
}

enum AuthError: Error, CustomStringConvertible {
    case invalidResponse
    case authenticationFailed(statusCode: Int)

    var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from authentication server"
        case .authenticationFailed(let statusCode):
            return "Authentication failed with status code \(statusCode)"
        }
    }
}

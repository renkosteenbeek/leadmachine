import Foundation

struct Config {
    let clientId: String
    let clientSecret: String
    let tenantId: String
    let userEmail: String
    let adminEmails: [String]
    let openAIKey: String

    static func load() throws -> Config {
        let fileURL = URL(fileURLWithPath: ".env")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ConfigError.fileNotFound
        }

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        var env: [String: String] = [:]

        contents.split(separator: "\n").forEach { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return }

            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                env[key] = value
            }
        }

        guard let clientId = env["GRAPH_CLIENT_ID"],
              let clientSecret = env["GRAPH_CLIENT_SECRET"],
              let tenantId = env["GRAPH_TENANT_ID"],
              let userEmail = env["SENDER_EMAIL"],
              let adminEmailsStr = env["ADMIN_EMAILS"],
              let openAIKey = env["OPENAI_API_KEY"] else {
            throw ConfigError.missingRequiredFields
        }

        let adminEmails = adminEmailsStr
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return Config(
            clientId: clientId,
            clientSecret: clientSecret,
            tenantId: tenantId,
            userEmail: userEmail,
            adminEmails: adminEmails,
            openAIKey: openAIKey
        )
    }
}

enum ConfigError: Error, CustomStringConvertible {
    case fileNotFound
    case missingRequiredFields

    var description: String {
        switch self {
        case .fileNotFound:
            return ".env file not found. Make sure you're running from the correct directory."
        case .missingRequiredFields:
            return "Missing required fields in .env file (GRAPH_CLIENT_ID, GRAPH_CLIENT_SECRET, GRAPH_TENANT_ID, SENDER_EMAIL, ADMIN_EMAILS, OPENAI_API_KEY)"
        }
    }
}

import Foundation
import Logging

actor GraphAPIClient {
    private let authenticator: Authenticator
    private let config: Config
    private let logger = Logger(label: "com.leadmachine.graphapi")
    private let baseURL = "https://graph.microsoft.com/v1.0"

    init(authenticator: Authenticator, config: Config) {
        self.authenticator = authenticator
        self.config = config
    }

    func getFolders() async throws -> [Folder] {
        let url = "\(baseURL)/users/\(config.userEmail)/mailFolders"
        let params = ["$select": "id,displayName,parentFolderId,totalItemCount,unreadItemCount", "$top": "50"]
        let response: FoldersResponse = try await makeRequest(url: url, queryParams: params)
        return response.value
    }

    func getChildFolders(parentId: String) async throws -> [Folder] {
        let url = "\(baseURL)/users/\(config.userEmail)/mailFolders/\(parentId)/childFolders"
        let params = ["$select": "id,displayName,parentFolderId,totalItemCount,unreadItemCount"]
        let response: FoldersResponse = try await makeRequest(url: url, queryParams: params)
        return response.value
    }

    func getMessages(folderId: String, top: Int = 50) async throws -> [Message] {
        let url = "\(baseURL)/users/\(config.userEmail)/mailFolders/\(folderId)/messages"
        let params = [
            "$select": "id,subject,from,receivedDateTime,body,bodyPreview,isRead",
            "$top": "\(top)",
            "$orderby": "receivedDateTime DESC"
        ]
        let response: MessagesResponse = try await makeRequest(url: url, queryParams: params)
        return response.value
    }

    func moveMessage(messageId: String, to destinationFolderId: String) async throws -> String {
        let url = "\(baseURL)/users/\(config.userEmail)/messages/\(messageId)/move"
        let body = ["destinationId": destinationFolderId]

        struct MoveResponse: Codable {
            let id: String
        }

        let response: MoveResponse = try await makeRequest(url: url, method: "POST", body: body)
        return response.id
    }

    func forwardMessage(messageId: String, to recipients: [String], comment: String) async throws {
        let url = "\(baseURL)/users/\(config.userEmail)/messages/\(messageId)/forward"

        struct ForwardRequest: Codable {
            let comment: String
            let toRecipients: [Recipient]

            struct Recipient: Codable {
                let emailAddress: EmailAddr

                struct EmailAddr: Codable {
                    let address: String
                }
            }
        }

        let request = ForwardRequest(
            comment: comment,
            toRecipients: recipients.map {
                ForwardRequest.Recipient(emailAddress: ForwardRequest.Recipient.EmailAddr(address: $0))
            }
        )

        let _: EmptyResponse? = try await makeRequest(url: url, method: "POST", body: request, expectNoContent: true)
    }

    private func makeRequest<T: Decodable>(
        url: String,
        method: String = "GET",
        queryParams: [String: String]? = nil,
        body: (any Encodable)? = nil,
        expectNoContent: Bool = false
    ) async throws -> T {
        var urlComponents = URLComponents(string: url)!

        if let queryParams {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let finalURL = urlComponents.url else {
            throw GraphAPIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method

        let token = try await authenticator.getAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GraphAPIError.invalidResponse
        }

        if expectNoContent && httpResponse.statusCode == 202 {
            return EmptyResponse() as! T
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("API Error (\(httpResponse.statusCode)): \(errorMessage)")
            throw GraphAPIError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

struct EmptyResponse: Codable {}

enum GraphAPIError: Error, CustomStringConvertible {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)

    var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed(let statusCode, let message):
            return "Request failed (\(statusCode)): \(message)"
        }
    }
}

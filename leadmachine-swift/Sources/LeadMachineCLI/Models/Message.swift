import Foundation

struct Message: Codable {
    let id: String
    let subject: String
    let from: EmailAddress
    let receivedDateTime: Date
    let bodyPreview: String
    let body: MessageBody?
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, subject, from, receivedDateTime, bodyPreview, body, isRead
    }
}

struct MessageBody: Codable {
    let contentType: String
    let content: String
}

struct EmailAddress: Codable {
    let emailAddress: EmailAddressDetails

    struct EmailAddressDetails: Codable {
        let address: String
        let name: String?
    }
}

struct MessagesResponse: Codable {
    let value: [Message]
}

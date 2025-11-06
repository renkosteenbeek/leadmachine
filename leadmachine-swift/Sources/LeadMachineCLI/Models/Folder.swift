import Foundation

struct Folder: Codable {
    let id: String
    let displayName: String
    let parentFolderId: String?
    let totalItemCount: Int?
    let unreadItemCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, displayName, parentFolderId, totalItemCount, unreadItemCount
    }
}

struct FoldersResponse: Codable {
    let value: [Folder]
}

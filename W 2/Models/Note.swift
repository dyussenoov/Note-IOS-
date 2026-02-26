import Foundation

struct Note: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var body: String?
}

struct NotePayload: Codable, Equatable {
    let title: String
    let body: String?
}

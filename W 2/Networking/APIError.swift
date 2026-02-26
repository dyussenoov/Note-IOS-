import Foundation

enum APIError: LocalizedError, Equatable {
    case badURL
    case network
    case http(Int)
    case decoding
    case encoding
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad URL."
        case .network: return "No internet connection (or network error)."
        case .http(let code): return "Server error. HTTP \(code)."
        case .decoding: return "Failed to decode server response."
        case .encoding: return "Failed to encode request body."
        case .unknown: return "Unknown error."
        }
    }
}

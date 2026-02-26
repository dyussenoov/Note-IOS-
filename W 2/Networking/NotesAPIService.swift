import Foundation
import Combine

final class NotesAPI {

    private let baseURL = URL(string: "https://69889f95780e8375a688c3b0.mockapi.io")!
    private let resourcePath = "Note"
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func makeURL(_ path: String? = nil) -> URL {
        var url = baseURL.appendingPathComponent(resourcePath)
        if let path { url = url.appendingPathComponent(path) }
        return url
    }

    private func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.http(http.statusCode)
        }
    }

    private func request(_ request: URLRequest) -> AnyPublisher<Data, APIError> {
        session.dataTaskPublisher(for: request)
            .mapError { _ in APIError.network }
            .tryMap { [weak self] output in
                guard let self else { throw APIError.unknown }
                try self.validateHTTP(output.response)
                return output.data
            }
            .mapError { $0 as? APIError ?? .unknown }
            .eraseToAnyPublisher()
    }

    // MARK: - GET
    func fetchNotes() -> AnyPublisher<[Note], APIError> {
        let url = makeURL()
        let request = URLRequest(url: url)

        return self.request(request)
            .decode(type: [Note].self, decoder: decoder)
            .mapError { error in
                if let apiError = error as? APIError { return apiError }
                return .decoding
            }
            .eraseToAnyPublisher()
    }

    // MARK: - POST
    func createNote(payload: NotePayload) -> AnyPublisher<Note, APIError> {
        let url = makeURL()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(payload)
        } catch {
            return Fail(error: APIError.encoding).eraseToAnyPublisher()
        }

        return self.request(request)
            .decode(type: Note.self, decoder: decoder)
            .mapError { error in
                if let apiError = error as? APIError { return apiError }
                return .decoding
            }
            .eraseToAnyPublisher()
    }

    // MARK: - PUT
    func updateNote(id: String, payload: NotePayload) -> AnyPublisher<Note, APIError> {
        let url = makeURL(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(payload)
        } catch {
            return Fail(error: APIError.encoding).eraseToAnyPublisher()
        }

        return self.request(request)
            .decode(type: Note.self, decoder: decoder)
            .mapError { error in
                if let apiError = error as? APIError { return apiError }
                return .decoding
            }
            .eraseToAnyPublisher()
    }

    // MARK: - DELETE
    func deleteNote(id: String) -> AnyPublisher<Void, APIError> {
        let url = makeURL(id)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        return self.request(request)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

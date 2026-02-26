import Foundation
import Combine

final class NoteEditorViewModel {

    @Published var title: String
    @Published var body: String

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorText: String? = nil

    private let api: NotesAPI
    private let noteID: String?
    private var cancellables = Set<AnyCancellable>()

    init(api: NotesAPI, note: Note? = nil) {
        self.api = api
        self.noteID = note?.id
        self.title = note?.title ?? ""
        self.body = note?.body ?? ""
    }

    var isEdit: Bool { noteID != nil }

    func save() -> AnyPublisher<Void, Never> {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorText = "Title is required."
            return Just(()).eraseToAnyPublisher()
        }

        isLoading = true
        errorText = nil

        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyOrNil = trimmedBody.isEmpty ? nil : trimmedBody

        let payload = NotePayload(title: trimmedTitle, body: bodyOrNil)

        let publisher: AnyPublisher<Note, APIError>
        if let id = noteID {
            publisher = api.updateNote(id: id, payload: payload)
        } else {
            publisher = api.createNote(payload: payload)
        }

        return publisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.errorText = err.localizedDescription
                }
            })
            .map { _ in () }
            .replaceError(with: ())
            .eraseToAnyPublisher()
    }
}

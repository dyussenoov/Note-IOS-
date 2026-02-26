import Foundation
import Combine

final class NotesListViewModel {

    @Published private(set) var notes: [Note] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorText: String? = nil

    private let api: NotesAPI
    private var cancellables = Set<AnyCancellable>()

    init(api: NotesAPI) {
        self.api = api
    }

    func loadNotes() {
        isLoading = true
        errorText = nil

        api.fetchNotes()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.errorText = err.localizedDescription
                }
            } receiveValue: { [weak self] notes in
                self?.notes = notes
            }
            .store(in: &cancellables)
    }

    func deleteNote(at index: Int) {
        let note = notes[index]
        isLoading = true
        errorText = nil

        api.deleteNote(id: note.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.errorText = err.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.notes.remove(at: index)
            }
            .store(in: &cancellables)
    }
}

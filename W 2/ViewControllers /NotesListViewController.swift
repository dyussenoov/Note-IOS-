import UIKit
import Combine

final class NotesListViewController: UIViewController {

    private let viewModel = NotesListViewModel(api: NotesAPI())
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .systemRed
        label.isHidden = true
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.isHidden = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadNotes()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Notes"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        [tableView, loadingLabel, errorLabel, retryButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func bind() {
        viewModel.$notes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.loadingLabel.isHidden = !isLoading
            }
            .store(in: &cancellables)

        viewModel.$errorText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                let hasError = (text != nil)
                self?.errorLabel.text = text
                self?.errorLabel.isHidden = !hasError
                self?.retryButton.isHidden = !hasError
            }
            .store(in: &cancellables)
    }

    @objc private func addTapped() {
        let vm = NoteEditorViewModel(api: NotesAPI(), note: nil)
        let vc = NoteEditorViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func retryTapped() {
        viewModel.loadNotes()
    }
}

extension NotesListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let note = viewModel.notes[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = note.title
        cfg.secondaryText = note.body
        cfg.secondaryTextProperties.numberOfLines = 1
        cell.contentConfiguration = cfg

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Tap -> Edit
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let note = viewModel.notes[indexPath.row]
        let vm = NoteEditorViewModel(api: NotesAPI(), note: note)
        let vc = NoteEditorViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }

    // Swipe-to-delete
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteNote(at: indexPath.row)
        }
    }
}

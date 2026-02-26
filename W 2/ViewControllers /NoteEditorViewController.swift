import UIKit
import Combine

final class NoteEditorViewController: UIViewController {

    private let viewModel: NoteEditorViewModel
    private var cancellables = Set<AnyCancellable>()

    private let titleField = UITextField()
    private let bodyTextView = UITextView()
    private let saveButton = UIButton(type: .system)

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Saving..."
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

    init(viewModel: NoteEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = viewModel.isEdit ? "Edit Note" : "New Note"

        titleField.borderStyle = .roundedRect
        titleField.placeholder = "Title (required)"
        titleField.text = viewModel.title
        titleField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        bodyTextView.layer.borderWidth = 1
        bodyTextView.layer.borderColor = UIColor.systemGray4.cgColor
        bodyTextView.layer.cornerRadius = 10
        bodyTextView.font = .systemFont(ofSize: 16)
        bodyTextView.text = viewModel.body

        saveButton.setTitle(viewModel.isEdit ? "Update" : "Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleField, bodyTextView, saveButton, loadingLabel, errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            bodyTextView.heightAnchor.constraint(equalToConstant: 220),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func bind() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.loadingLabel.isHidden = !isLoading
                self?.saveButton.isEnabled = !isLoading
            }
            .store(in: &cancellables)

        viewModel.$errorText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                let hasError = (text != nil)
                self?.errorLabel.text = text
                self?.errorLabel.isHidden = !hasError
            }
            .store(in: &cancellables)
    }

    @objc private func titleChanged() {
        viewModel.title = titleField.text ?? ""
    }

    @objc private func saveTapped() {
        viewModel.body = bodyTextView.text ?? ""

        viewModel.save()
            .sink { [weak self] in
                if self?.viewModel.errorText == nil {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            .store(in: &cancellables)
    }
}

import SwiftUI

@main
struct W_2App: App {
    var body: some Scene {
        WindowGroup {
            UIKitRootView()
        }
    }
}

struct UIKitRootView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = NotesListViewController()
        return UINavigationController(rootViewController: vc)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

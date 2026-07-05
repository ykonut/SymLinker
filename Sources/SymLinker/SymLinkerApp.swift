import SwiftUI

@main
struct SymLinkerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 420, height: 480)
    }
}

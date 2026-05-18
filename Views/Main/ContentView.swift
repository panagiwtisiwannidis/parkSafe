import SwiftUI

// MARK: - ContentView
// Pure router. Decides which screen to show. No logic of its own.

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            MainView()
        } else {
            OnboardingView()
        }
    }
}

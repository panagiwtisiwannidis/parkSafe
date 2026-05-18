import SwiftUI

@main
struct ParkingApp: App {
    @StateObject private var viewModel = ParkingViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        // HIGH FIX: Clear badge every time app returns to foreground
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.resetBadge()
            }
        }
    }
}

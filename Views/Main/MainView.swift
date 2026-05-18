import SwiftUI

// MARK: - MainView
// Displays either the saved spot UI or the empty state.
// Reads from ViewModel only — no direct service access.

struct MainView: View {
    @EnvironmentObject var vm: ParkingViewModel

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 24) {
                    HeaderView()

                    if let spot = vm.savedSpot {
                        SavedSpotCard(spot: spot)
                        NavigationCard()
                        NotificationToggleCard()
                        ClearSpotButton()
                    } else {
                        EmptyStateView()
                        SaveSpotButton()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            vm.locateUser()
            vm.refreshNotificationStatus()
        }
    }
}

// MARK: - Shared Background

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color("BGTop"), Color("BGBottom")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

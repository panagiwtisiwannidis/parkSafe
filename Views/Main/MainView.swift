import SwiftUI

// MARK: - MainView

struct MainView: View {
    @EnvironmentObject var vm: ParkingViewModel
    @State private var selectedSpotID: UUID?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 20) {
                    HeaderView()

                    if vm.savedSpots.isEmpty {
                        EmptyStateView()
                        SaveSpotButton()
                    } else {
                        spotPager
                        NotificationToggleCard()
                        AddSpotButton()
                        if let id = selectedSpotID {
                            ClearSpotButton(spotId: id)
                        }
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
            if selectedSpotID == nil { selectedSpotID = vm.savedSpots.first?.id }
        }
        .onChange(of: vm.savedSpots.map(\.id)) { oldIDs, newIDs in
            if newIDs.count > oldIDs.count {
                // new spot added — jump to it
                withAnimation { selectedSpotID = newIDs.first }
            } else if let current = selectedSpotID, !newIDs.contains(current) {
                selectedSpotID = newIDs.first
            }
        }
    }

    // MARK: - Spot Pager

    @ViewBuilder
    private var spotPager: some View {
        VStack(spacing: 10) {
            if vm.savedSpots.count > 1 {
                pageIndicator
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(vm.savedSpots) { spot in
                        VStack(spacing: 16) {
                            SavedSpotCard(spot: spot)
                            NavigationCard(spot: spot)
                        }
                        .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedSpotID)
            // clip negative margin so cards don't bleed into header
            .padding(.horizontal, -20)
            .padding(.leading, 20)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(vm.savedSpots) { spot in
                Capsule()
                    .fill(spot.id == selectedSpotID ? Color.white : Color.white.opacity(0.3))
                    .frame(width: spot.id == selectedSpotID ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: selectedSpotID)
            }
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

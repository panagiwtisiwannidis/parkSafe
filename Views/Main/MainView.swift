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
                        ReminderCard()
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
                        SpotPageView(spot: spot)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedSpotID)
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

// MARK: - Spot Page (one card in the carousel, owns swipe-up-to-delete)

private struct SpotPageView: View {
    @EnvironmentObject var vm: ParkingViewModel
    let spot: ParkingSpot

    @State private var dragY: CGFloat = 0
    @State private var deleting = false

    var body: some View {
        VStack(spacing: 16) {
            SavedSpotCard(spot: spot)
            NavigationCard(spot: spot)
        }
        .offset(y: dragY)
        .opacity(deleting ? 0 : max(0, 1 - abs(dragY) / 160.0))
        .gesture(
            DragGesture()
                .onChanged { v in
                    guard !deleting else { return }
                    let t = v.translation
                    // only upward drags that are more vertical than horizontal
                    if t.height < 0 && abs(t.height) > abs(t.width) {
                        dragY = t.height
                    }
                }
                .onEnded { v in
                    guard !deleting else { return }
                    let t = v.translation
                    if t.height < -80 && abs(t.height) > abs(t.width) {
                        withAnimation(.easeIn(duration: 0.22)) {
                            dragY = -350
                            deleting = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            vm.clearSpot(id: spot.id)
                        }
                    } else {
                        withAnimation(.spring(response: 0.35)) { dragY = 0 }
                    }
                }
        )
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

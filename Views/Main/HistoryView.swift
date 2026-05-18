import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var vm: ParkingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.spotHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle(Strings.History.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Clear.cancel) { dismiss() }
                }
                if !vm.spotHistory.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(Strings.History.clearAll, role: .destructive) {
                            showClearConfirm = true
                        }
                    }
                }
            }
            .alert(Strings.History.clearConfirmTitle,
                   isPresented: $showClearConfirm) {
                Button(Strings.History.clearConfirmAction, role: .destructive) {
                    vm.clearHistory()
                }
                Button(Strings.Clear.cancel, role: .cancel) {}
            } message: {
                Text(Strings.History.clearConfirmMessage)
            }
        }
    }

    private var historyList: some View {
        List {
            ForEach(vm.spotHistory) { spot in
                HistoryRowView(spot: spot)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let idx = vm.spotHistory.firstIndex(where: { $0.id == spot.id }) {
                                vm.deleteFromHistory(at: IndexSet(integer: idx))
                            }
                        } label: {
                            Label(Strings.Clear.action, systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text(Strings.History.empty)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Row

private struct HistoryRowView: View {
    @EnvironmentObject var vm: ParkingViewModel
    let spot: ParkingSpot

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "parkingsign")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(spot.address ?? spot.coordinateString)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(spot.relativeTime)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    if let note = spot.note, !note.isEmpty {
                        Text("·")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(note)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Menu {
                Button {
                    vm.navigateWithAppleMaps(spot: spot)
                } label: {
                    Label("Apple Maps", systemImage: "map")
                }
                Button {
                    vm.navigateWithGoogleMaps(spot: spot)
                } label: {
                    Label("Google Maps", systemImage: "map.fill")
                }
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

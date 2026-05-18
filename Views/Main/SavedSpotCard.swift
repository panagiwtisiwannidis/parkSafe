import SwiftUI
import MapKit

struct SavedSpotCard: View {
    @EnvironmentObject var vm: ParkingViewModel
    let spot: ParkingSpot
    @State private var showNoteEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            mapView
            infoRow
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorSheet(spotId: spot.id, initialNote: spot.note)
                .environmentObject(vm)
        }
    }

    private var mapView: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: spot.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        ))) {
            Annotation("", coordinate: spot.coordinate) {
                ParkingPinView()
                    .accessibilityLabel(Strings.Map.pinLabel)
                    .accessibilityHint(Strings.Map.pinHint)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var infoRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let address = spot.address {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                    Text(address)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 12) {
                InfoChip(icon: "clock.fill", text: spot.relativeTime)
                if let dist = vm.distance(to: spot) {
                    InfoChip(icon: "figure.walk", text: dist)
                }
                Spacer()
            }

            Divider()
                .background(.white.opacity(0.12))

            Button { showNoteEditor = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: spot.note != nil ? "note.text" : "square.and.pencil")
                        .font(.system(size: 14))
                        .foregroundColor(spot.note != nil ? .accentColor : .white.opacity(0.35))
                    Text(spot.note ?? Strings.Note.add)
                        .font(.system(size: 14))
                        .foregroundColor(spot.note != nil ? .white.opacity(0.85) : .white.opacity(0.4))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.25))
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Note Editor Sheet

struct NoteEditorSheet: View {
    @EnvironmentObject var vm: ParkingViewModel
    @Environment(\.dismiss) private var dismiss
    let spotId: UUID
    @State private var text: String

    init(spotId: UUID, initialNote: String?) {
        self.spotId = spotId
        _text = State(initialValue: initialNote ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField(Strings.Note.placeholder, text: $text, axis: .vertical)
                    .lineLimit(3...8)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding()
                Spacer()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(Strings.Note.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Clear.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Note.save) {
                        vm.updateSpotNote(id: spotId, note: text.isEmpty ? nil : text)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

import SwiftUI
import MapKit

struct SavedSpotCard: View {
    @EnvironmentObject var vm: ParkingViewModel
    let spot: ParkingSpot

    @State private var region: MKCoordinateRegion

    init(spot: ParkingSpot) {
        self.spot = spot
        _region = State(initialValue: MKCoordinateRegion(
            center: spot.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Map
            Map(coordinateRegion: $region, annotationItems: [spot]) { item in
                MapAnnotation(coordinate: item.coordinate) {
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

            // Info row
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
                    InfoChip(icon: "clock.fill",   text: spot.relativeTime)
                    if let dist = vm.distanceToSpot {
                        InfoChip(icon: "figure.walk", text: dist)
                    }
                    Spacer()
                }
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
}

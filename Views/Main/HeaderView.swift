import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var vm: ParkingViewModel
    @State private var showHistory = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ParkSafe")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(vm.savedSpots.isEmpty ? Strings.Header.subtitleEmpty : Strings.Header.subtitleSaved)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            HStack(spacing: 10) {
                Button {
                    showHistory = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel(Strings.History.title)
                .sheet(isPresented: $showHistory) {
                    HistoryView()
                        .environmentObject(vm)
                }

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "car.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.top, 8)
    }
}

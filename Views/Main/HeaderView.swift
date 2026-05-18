import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var vm: ParkingViewModel

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ParkSafe")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(vm.savedSpot != nil ? Strings.Header.subtitleSaved : Strings.Header.subtitleEmpty)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "car.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 8)
    }
}

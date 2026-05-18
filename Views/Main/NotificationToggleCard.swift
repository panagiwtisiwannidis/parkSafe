import SwiftUI

struct NotificationToggleCard: View {
    @EnvironmentObject var vm: ParkingViewModel
    @State private var iconBounce = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(vm.notificationsEnabled ? Color.orange.opacity(0.2) : Color.white.opacity(0.07))
                    .frame(width: 50, height: 50)
                Image(systemName: vm.notificationsEnabled ? "bell.badge.fill" : "bell.slash.fill")
                    .font(.system(size: 22))
                    .foregroundColor(vm.notificationsEnabled ? .orange : .white.opacity(0.4))
                    .scaleEffect(iconBounce ? 1.2 : 1.0)
            }
            .animation(.spring(response: 0.3), value: vm.notificationsEnabled)

            VStack(alignment: .leading, spacing: 3) {
                Text(Strings.Notif.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(vm.notificationsEnabled ? Strings.Notif.subtitleActive : Strings.Notif.subtitleInactive)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { vm.notificationsEnabled },
                set: { _ in
                    withAnimation(.spring(response: 0.3)) {
                        iconBounce = true
                        vm.toggleNotifications()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { iconBounce = false }
                }
            ))
            .tint(.orange)
            .labelsHidden()
            .accessibilityLabel(Strings.Notif.title)
            .accessibilityHint(vm.notificationsEnabled ? Strings.Notif.subtitleActive : Strings.Notif.subtitleInactive)
        }
        .cardStyle()
    }
}

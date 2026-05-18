import SwiftUI

struct NavigationCard: View {
    @EnvironmentObject var vm: ParkingViewModel
    let spot: ParkingSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: Strings.Nav.sectionTitle)

            HStack(spacing: 12) {
                NavButton(
                    icon: "apple.logo",
                    title: Strings.Nav.appleTitle,
                    subtitle: Strings.Nav.appleSubtitle,
                    color: Color(red: 0.2, green: 0.6, blue: 1.0),
                    action: { vm.navigateWithAppleMaps(spot: spot) }
                )
                NavButton(
                    icon: "map.fill",
                    title: Strings.Nav.googleTitle,
                    subtitle: Strings.Nav.googleSubtitle,
                    color: Color(red: 0.2, green: 0.75, blue: 0.45),
                    action: { vm.navigateWithGoogleMaps(spot: spot) }
                )
            }
        }
        .cardStyle()
    }
}

// MARK: - NavButton

struct NavButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.1))  { isPressed = true  } }
                .onEnded   { _ in withAnimation(.easeOut(duration: 0.15)) { isPressed = false } }
        )
    }
}

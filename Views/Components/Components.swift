import SwiftUI

// MARK: - ParkingPinView
// Animated map annotation pin.

struct ParkingPinView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.3))
                .frame(width: 44, height: 44)
                .scaleEffect(pulse ? 1.4 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
            Circle()
                .fill(Color.accentColor)
                .frame(width: 26, height: 26)
            Image(systemName: "car.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .onAppear { pulse = true }
    }
}

// MARK: - InfoChip
// Small pill showing icon + label.

struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accentColor)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - PermissionBadgeView
// Shown during onboarding to explain each permission.

struct PermissionBadgeView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - SectionLabel
// Uppercase section header label.

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.5))
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

// MARK: - Card Style Modifier

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

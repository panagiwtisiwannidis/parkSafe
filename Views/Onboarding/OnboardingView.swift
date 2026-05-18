import SwiftUI

// MARK: - OnboardingView
// Walks the user through 4 steps, requesting permissions at the right moment.
// All permission calls go through the ViewModel.

struct OnboardingView: View {
    @EnvironmentObject var vm: ParkingViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var step = 0
    @State private var animatedIn = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()
                iconArea
                Spacer().frame(height: 36)
                textArea
                Spacer()
                if step == 1 || step == 2 { permissionBadge.padding(.bottom, 24) }
                ctaButton.padding(.horizontal, 24)
                if step == 1 || step == 2 { skipLink.padding(.top, 14) }
                Spacer().frame(height: 44)
            }

            // Progress dots
            VStack {
                Spacer()
                stepDots.padding(.bottom, 114)
            }
        }
        .onAppear { animateIn() }
    }

    // MARK: - Subviews

    private var iconArea: some View {
        ZStack {
            Circle().fill(.white.opacity(0.08)).frame(width: 130, height: 130)
            Circle().fill(.white.opacity(0.10)).frame(width: 96,  height: 96)
            Image(systemName: stepIcon)
                .font(.system(size: 46, weight: .semibold))
                .foregroundColor(.white)
                .id(step)
                .transition(.scale.combined(with: .opacity))
        }
        .opacity(animatedIn ? 1 : 0)
        .offset(y: animatedIn ? 0 : 30)
    }

    private var textArea: some View {
        VStack(spacing: 12) {
            Text(stepTitle)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .id("t\(step)")
            Text(stepBody)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 28)
                .id("b\(step)")
        }
        .opacity(animatedIn ? 1 : 0)
        .offset(y: animatedIn ? 0 : 20)
    }

    private var permissionBadge: some View {
        PermissionBadgeView(
            icon:        step == 1 ? "location.fill" : "bell.badge.fill",
            title:       step == 1 ? Strings.Permission.locationTitle       : Strings.Permission.notifTitle,
            description: step == 1 ? Strings.Permission.locationDescription : Strings.Permission.notifDescription,
            color:       step == 1 ? Color(red: 0.2, green: 0.6, blue: 1.0) : .orange
        )
        .padding(.horizontal, 24)
        .opacity(animatedIn ? 1 : 0)
    }

    private var ctaButton: some View {
        Button(action: handleCTA) {
            HStack(spacing: 10) {
                Text(ctaLabel)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                if step < 3 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(colors: [.white, .white.opacity(0.9)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animatedIn ? 1 : 0)
    }

    private var skipLink: some View {
        Button(action: advance) {
            Text(Strings.Onboarding.skip)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == min(step, 2) ? Color.white : Color.white.opacity(0.25))
                    .frame(width: i == min(step, 2) ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.35), value: step)
            }
        }
    }

    // MARK: - Step Content

    private var stepIcon: String {
        [
            "parkingsign.circle.fill",
            "location.circle.fill",
            "bell.circle.fill",
            "checkmark.circle.fill"
        ][min(step, 3)]
    }

    private var stepTitle: String {
        Strings.Onboarding.steps[min(step, Strings.Onboarding.steps.count - 1)].title
    }

    private var stepBody: String {
        Strings.Onboarding.steps[min(step, Strings.Onboarding.steps.count - 1)].body
    }

    private var ctaLabel: String {
        Strings.Onboarding.steps[min(step, Strings.Onboarding.steps.count - 1)].cta
    }

    // MARK: - Actions

    private func handleCTA() {
        switch step {
        case 0: advance()
        case 1:
            vm.requestLocationPermission()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advance() }
        case 2:
            vm.requestNotificationPermission { _ in advance() }
        default:
            hasSeenOnboarding = true
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.4)) { animatedIn = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            step += 1
            animateIn()
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.1)) {
            animatedIn = true
        }
    }
}

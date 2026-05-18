import SwiftUI

// MARK: - EmptyStateView

struct EmptyStateView: View {
    @State private var bobbing = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(.white.opacity(0.06)).frame(width: 120, height: 120)
                Circle().fill(.white.opacity(0.09)).frame(width: 88,  height: 88)
                Image(systemName: "car.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(y: bobbing ? -6 : 0)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: bobbing)
            }
            .padding(.top, 30)
            .onAppear { bobbing = true }

            VStack(spacing: 8) {
                Text(Strings.Empty.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(Strings.Empty.description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - SaveSpotButton

struct SaveSpotButton: View {
    @EnvironmentObject var vm: ParkingViewModel
    @State private var isPressed = false
    @State private var showDeniedAlert = false

    var body: some View {
        VStack(spacing: 12) {
            Button(action: handleSave) {
                HStack(spacing: 12) {
                    if vm.isLocating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "parkingsign.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    Text(vm.isLocating ? Strings.Button.saving : Strings.Button.save)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(colors: [.white, .white.opacity(0.88)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(vm.isLocating)
            .accessibilityLabel(Strings.Button.save)
            .accessibilityHint("Saves your current GPS location as your parking spot")
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in withAnimation(.easeIn(duration: 0.1))  { isPressed = true  } }
                    .onEnded   { _ in withAnimation(.easeOut(duration: 0.15)) { isPressed = false } }
            )

            if let error = vm.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .alert(Strings.Location.deniedTitle, isPresented: $showDeniedAlert) {
            Button(Strings.Location.deniedSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(Strings.Location.deniedCancel, role: .cancel) {}
        } message: {
            Text(Strings.Location.deniedMessage)
        }
    }

    private func handleSave() {
        if vm.locationIsDenied {
            showDeniedAlert = true
            return
        }
        vm.locateAndSave()
    }
}

// MARK: - AddSpotButton

struct AddSpotButton: View {
    @EnvironmentObject var vm: ParkingViewModel
    @State private var isPressed = false
    @State private var showDeniedAlert = false

    var body: some View {
        Button(action: handleSave) {
            HStack(spacing: 10) {
                if vm.isLocating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
                Text(vm.isLocating ? Strings.Button.saving : Strings.Button.addSpot)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.accentColor.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(vm.isLocating)
        .accessibilityLabel(Strings.Button.addSpot)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.1))  { isPressed = true  } }
                .onEnded   { _ in withAnimation(.easeOut(duration: 0.15)) { isPressed = false } }
        )
        .alert(Strings.Location.deniedTitle, isPresented: $showDeniedAlert) {
            Button(Strings.Location.deniedSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(Strings.Location.deniedCancel, role: .cancel) {}
        } message: {
            Text(Strings.Location.deniedMessage)
        }
    }

    private func handleSave() {
        if vm.locationIsDenied { showDeniedAlert = true; return }
        vm.locateAndSave()
    }
}

// MARK: - ClearSpotButton

struct ClearSpotButton: View {
    @EnvironmentObject var vm: ParkingViewModel
    let spotId: UUID
    @State private var showConfirm = false

    var body: some View {
        Button(action: { showConfirm = true }) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text(Strings.Button.clear)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.red.opacity(0.8))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.red.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Strings.Button.clear)
        .accessibilityHint("Removes saved spot and cancels all reminders")
        .confirmationDialog(Strings.Clear.confirmTitle, isPresented: $showConfirm, titleVisibility: .visible) {
            Button(Strings.Clear.action, role: .destructive) {
                withAnimation(.spring(response: 0.4)) { vm.clearSpot(id: spotId) }
            }
            Button(Strings.Clear.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Clear.confirmMessage)
        }
    }
}

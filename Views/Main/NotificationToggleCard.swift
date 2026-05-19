import SwiftUI

// MARK: - ReminderCard
// Replaces the old hourly-toggle with a single user-chosen reminder time.

struct ReminderCard: View {
    @EnvironmentObject var vm: ParkingViewModel
    @State private var showCustomPicker = false

    private let quickOptions: [(label: String, minutes: Double)] = [
        ("30m", 30), ("1h", 60), ("2h", 120), ("3h", 180)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: Strings.Reminder.title)

            if let date = vm.reminderDate, date > Date() {
                activeRow(date: date)
            } else {
                idleRows
            }
        }
        .cardStyle()
        .sheet(isPresented: $showCustomPicker) {
            CustomReminderSheet()
                .environmentObject(vm)
        }
    }

    // MARK: - Active state (reminder is set)

    private func activeRow(date: Date) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(formattedTime(date))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(relativeLabel(date))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) { vm.cancelReminder() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.22))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Idle state (no reminder)

    private var idleRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Reminder.hint)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))

            HStack(spacing: 8) {
                ForEach(quickOptions, id: \.label) { opt in
                    Button(opt.label) {
                        vm.setReminder(at: Date().addingTimeInterval(opt.minutes * 60))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .buttonStyle(PlainButtonStyle())
                }

                Button(Strings.Reminder.custom) {
                    showCustomPicker = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = Calendar.current.isDateInToday(date) ? .none : .medium
        return f.string(from: date)
    }

    private func relativeLabel(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Custom Reminder Sheet

private struct CustomReminderSheet: View {
    @EnvironmentObject var vm: ParkingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    Strings.Reminder.title,
                    selection: $selectedDate,
                    in: Date()...
                )
                .datePickerStyle(.compact)
            }
            .navigationTitle(Strings.Reminder.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Clear.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Reminder.confirm) {
                        vm.setReminder(at: selectedDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

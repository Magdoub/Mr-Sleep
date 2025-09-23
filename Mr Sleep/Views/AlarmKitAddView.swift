import AlarmKit
import SwiftUI

struct AlarmKitAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmKitViewModel.self) private var viewModel
    
    @State private var userInput = AlarmKitForm()
    @State private var isScheduling = false
    
    var body: some View {
        NavigationStack {
            Form {
                labelSection
                
                sleepContextSection
                
                wakeUpReasonSection
                
                countdownSection
                
                scheduleSection
                
                secondaryButtonSection
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        scheduleAlarm()
                    } label: {
                        if isScheduling {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Add")
                        }
                    }
                    .disabled(!userInput.isValidAlarm || isScheduling)
                }
            }
        }
    }
    
    var labelSection: some View {
        Section {
            Label {
                TextField("Alarm Label", text: $userInput.label)
            } icon: {
                Image(systemName: "character.cursor.ibeam")
                    .foregroundColor(.accentColor)
            }
        } header: {
            Text("Label")
        } footer: {
            Text("Optional custom name for your alarm")
        }
    }
    
    var sleepContextSection: some View {
        Section {
            Picker("Sleep Type", selection: $userInput.selectedSleepContext) {
                Text("None").tag(nil as MrSleepAlarmMetadata.SleepContext?)
                
                ForEach(MrSleepAlarmMetadata.SleepContext.allCases, id: \.self) { context in
                    Label {
                        Text(context.rawValue)
                    } icon: {
                        Image(systemName: context.icon)
                    }
                    .tag(context as MrSleepAlarmMetadata.SleepContext?)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Sleep Context")
        } footer: {
            if let context = userInput.selectedSleepContext {
                Text("Duration: \(context.duration.formattedDuration())")
            } else {
                Text("Choose a sleep type for quick setup")
            }
        }
    }
    
    var wakeUpReasonSection: some View {
        Section {
            Picker("Wake Up Reason", selection: $userInput.selectedWakeUpReason) {
                ForEach(MrSleepAlarmMetadata.WakeUpReason.allCases, id: \.self) { reason in
                    Label {
                        Text(reason.rawValue)
                    } icon: {
                        Image(systemName: reason.icon)
                    }
                    .tag(reason)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Wake Up Reason")
        } footer: {
            Text("Why do you need to wake up?")
        }
    }
    
    var countdownSection: some View {
        Section {
            Toggle(isOn: $userInput.preAlertEnabled) {
                Label("Countdown Timer", systemImage: "timer")
            }
            
            if userInput.preAlertEnabled {
                TimePickerView(
                    hour: $userInput.selectedPreAlert.hour,
                    min: $userInput.selectedPreAlert.min,
                    sec: $userInput.selectedPreAlert.sec
                )
            }
        } header: {
            Text("Timer")
        } footer: {
            if userInput.preAlertEnabled {
                Text("Timer will count down from \(userInput.selectedPreAlert.formattedString)")
            } else {
                Text("Enable for countdown timer functionality")
            }
        }
    }
    
    var scheduleSection: some View {
        Section {
            Toggle(isOn: $userInput.scheduleEnabled) {
                Label("Schedule", systemImage: "calendar")
            }
            
            if userInput.scheduleEnabled {
                DatePicker("Time", selection: $userInput.selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                
                daysOfTheWeekSection
            }
        } header: {
            Text("Schedule")
        } footer: {
            if userInput.scheduleEnabled {
                if userInput.selectedDays.isEmpty {
                    Text("One-time alarm at \(userInput.selectedDate.formatted(date: .omitted, time: .shortened))")
                } else {
                    Text("Repeats on \(userInput.selectedDays.map(\.localizedAbbreviation).joined(separator: ", "))")
                }
            } else {
                Text("Enable for scheduled alarms")
            }
        }
    }
    
    var daysOfTheWeekSection: some View {
        HStack(spacing: 8) {
            ForEach(Locale.autoupdatingCurrent.orderedWeekdays, id: \.self) { weekday in
                Button {
                    if userInput.isSelected(day: weekday) {
                        userInput.selectedDays.remove(weekday)
                    } else {
                        userInput.selectedDays.insert(weekday)
                    }
                } label: {
                    Text(weekday.localizedAbbreviation)
                        .font(.caption2)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(userInput.isSelected(day: weekday) ? .accentColor : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var secondaryButtonSection: some View {
        Section {
            Picker("Secondary Action", selection: $userInput.selectedSecondaryButton) {
                ForEach(AlarmKitForm.SecondaryButtonOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            
            if userInput.selectedSecondaryButton == .countdown {
                TimePickerView(
                    hour: $userInput.selectedPostAlert.hour,
                    min: $userInput.selectedPostAlert.min,
                    sec: $userInput.selectedPostAlert.sec
                )
            }
        } header: {
            Text("Secondary Button")
        } footer: {
            Text(userInput.selectedSecondaryButton.description)
        }
    }
    
    func scheduleAlarm() {
        isScheduling = true
        
        Task {
            await viewModel.scheduleAlarm(with: userInput)
            
            await MainActor.run {
                isScheduling = false
                dismiss()
            }
        }
    }
}

// MARK: - Time Picker Component
struct TimePickerView: View {
    @Binding var hour: Int
    @Binding var min: Int
    @Binding var sec: Int
    
    private let labelOffset = 40.0
    
    var body: some View {
        HStack(spacing: 0) {
            pickerRow(title: "hr", range: 0..<24, selection: $hour)
            pickerRow(title: "min", range: 0..<60, selection: $min)
            pickerRow(title: "sec", range: 0..<60, selection: $sec)
        }
        .frame(height: 120)
    }
    
    func pickerRow(title: String, range: Range<Int>, selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(range, id: \.self) { value in
                Text("\(value)")
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .overlay(alignment: .trailing) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(x: labelOffset)
        }
    }
}

// MARK: - Quick Setup Buttons
struct QuickSetupButtons: View {
    @Binding var userInput: AlarmKitForm
    
    var body: some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickSetupButton("Quick Nap", "20m", "powersleep") {
                    userInput = .quickNap()
                }
                
                quickSetupButton("Power Nap", "30m", "bolt.circle") {
                    userInput = .powerNap()
                }
                
                quickSetupButton("Short Sleep", "1.5h", "moon.circle") {
                    userInput = .shortSleep()
                }
                
                quickSetupButton("Morning", "7 AM", "sunrise") {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    let morningTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow) ?? Date()
                    userInput = .morningAlarm(at: morningTime)
                }
            }
        } header: {
            Text("Quick Setup")
        } footer: {
            Text("Tap a preset to quickly configure common alarm types")
        }
    }
    
    func quickSetupButton(_ title: String, _ subtitle: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Locale Extensions
extension Locale {
    var orderedWeekdays: [Locale.Weekday] {
        let days: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        if let firstDayIdx = days.firstIndex(of: firstDayOfWeek), firstDayIdx != 0 {
            return Array(days[firstDayIdx...] + days[0..<firstDayIdx])
        }
        return days
    }
}

extension MrSleepAlarmMetadata.SleepContext: CaseIterable {
    public static var allCases: [MrSleepAlarmMetadata.SleepContext] {
        [.quickNap, .powerNap, .shortSleep, .normalSleep, .longSleep, .deepSleep]
    }
}

#Preview {
    AlarmKitAddView()
        .environment(AlarmKitViewModel())
}
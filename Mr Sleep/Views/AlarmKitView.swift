import AlarmKit
import SwiftUI

struct AlarmKitView: View {
    @State private var viewModel = AlarmKitViewModel()
    @State private var showAddSheet = false
    @State private var selectedAlarmToEdit: ItsukiAlarm?
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Alarms")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if viewModel.alarmManager.isAlarmKitAvailable {
                        ToolbarItem(placement: .topBarTrailing) {
                            addButton
                        }
                    }
                }
                .sheet(isPresented: $showAddSheet) {
                    AlarmKitAddView()
                        .environment(viewModel)
                }
        }
        .environment(viewModel)
        .alert("AlarmKit Error", isPresented: .constant(viewModel.alarmManager.alarmKitError != nil && viewModel.alarmManager.isAlarmKitAvailable)) {
            Button("OK") {
                viewModel.alarmManager.alarmKitError = nil
            }
            
            if case .authorizationDenied = viewModel.alarmManager.alarmKitError {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
        } message: {
            Text(viewModel.alarmManager.alarmKitError?.localizedDescription ?? "Unknown error")
        }
        .tint(.accentColor)
    }
    
    var addButton: some View {
        Button {
            showAddSheet.toggle()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
        }
    }
    
    
    @ViewBuilder var content: some View {
        if !viewModel.alarmManager.isAlarmKitAvailable {
            alarmKitUnavailableView
        } else if viewModel.hasUpcomingAlarms {
            simpleAlarmListView
        } else {
            emptyStateView
        }
    }
    
    var simpleAlarmListView: some View {
        List {
            ForEach(viewModel.runningAlarms, id: \.id) { alarm in
                SimpleAlarmCell(alarm: alarm, onEdit: { alarm in
                    selectedAlarmToEdit = alarm
                })
                    .environment(viewModel)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let alarm = viewModel.runningAlarms[index]
                    Task {
                        await viewModel.deleteAlarm(alarm)
                    }
                }
            }
        }
        .listStyle(.plain)
        .sheet(item: $selectedAlarmToEdit) { alarmToEdit in
            AlarmKitEditView(alarm: alarmToEdit)
                .environment(viewModel)
        }
    }
    
    var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Alarms", systemImage: "alarm.waves.left.and.right")
        } description: {
            Text("Tap the + button to create your first alarm")
        } actions: {
            Button {
                showAddSheet.toggle()
            } label: {
                Text("Create Alarm")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
    }
    
    var alarmKitUnavailableView: some View {
        ContentUnavailableView {
            Label("AlarmKit Unavailable", systemImage: "exclamationmark.triangle")
        } description: {
            if let error = viewModel.alarmManager.alarmKitError {
                Text(error.localizedDescription)
            } else {
                Text("AlarmKit is not available on this device")
            }
        } actions: {
            VStack(spacing: 16) {
                if let error = viewModel.alarmManager.alarmKitError,
                   let recoverySuggestion = error.recoverySuggestion {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.orange)
                            Text("Suggestion")
                                .font(.headline)
                        }
                        
                        Text(recoverySuggestion)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                HStack(spacing: 12) {
                    Button {
                        // Try to reinitialize AlarmKit
                        Task {
                            _ = await viewModel.alarmManager.checkAuthorization()
                        }
                    } label: {
                        Text("Retry")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    if case .authorizationDenied = viewModel.alarmManager.alarmKitError {
                        Button {
                            // Open Settings app
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        } label: {
                            Text("Settings")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

// MARK: - Simple Alarm Cell
struct SimpleAlarmCell: View {
    let alarm: ItsukiAlarm
    let onEdit: (ItsukiAlarm) -> Void
    @Environment(AlarmKitViewModel.self) private var viewModel
    @State private var isEnabled = true
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Time Display - Tappable area for editing
            VStack(alignment: .leading, spacing: 4) {
                if let scheduledTime = alarm.scheduledTime {
                    Text(scheduledTime, style: .time)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                } else {
                    Text("Timer")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                }
                
                // Status
                Text(alarm.state == .scheduled ? "Alarm" : alarm.stateLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit(alarm)
            }
            
            // Toggle Switch
            Toggle("", isOn: $isEnabled)
                .scaleEffect(0.8)
                .onChange(of: isEnabled) { _, newValue in
                    Task {
                        if newValue {
                            // Enable/resume alarm logic here
                            if alarm.state == .paused {
                                await viewModel.resumeAlarm(alarm)
                            }
                        } else {
                            // Disable/pause alarm logic here
                            if alarm.state == .countdown || alarm.state == .scheduled {
                                await viewModel.pauseAlarm(alarm)
                            }
                        }
                    }
                }
        }
        .padding(.vertical, 8)
        .onAppear {
            isEnabled = alarm.state != .paused
        }
    }
}

// MARK: - Extensions
extension TimeInterval {
    func formattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }
}

extension Locale.Weekday {
    var localizedAbbreviation: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        @unknown default: "?"
        }
    }
}

#Preview {
    AlarmKitView()
}
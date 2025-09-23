import AlarmKit
import SwiftUI

struct AlarmKitView: View {
    @State private var viewModel = AlarmKitViewModel()
    @State private var showAddSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("AlarmKit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        quickActionsMenu
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        addButton
                    }
                }
                .sheet(isPresented: $showAddSheet) {
                    AlarmKitAddView()
                        .environment(viewModel)
                }
        }
        .environment(viewModel)
        .alert("Error", isPresented: $viewModel.alarmManager.showError) {
            Button("OK") {
                viewModel.alarmManager.showError = false
            }
        } message: {
            Text(viewModel.alarmManager.error?.localizedDescription ?? "Unknown error")
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
    
    var quickActionsMenu: some View {
        Menu {
            Section("Quick Timers") {
                Button {
                    Task {
                        await viewModel.scheduleQuickNap()
                    }
                } label: {
                    Label("Quick Nap (20m)", systemImage: "powersleep")
                }
                
                Button {
                    Task {
                        await viewModel.schedulePowerNap()
                    }
                } label: {
                    Label("Power Nap (30m)", systemImage: "bolt.circle")
                }
                
                Button {
                    Task {
                        await viewModel.scheduleShortSleep()
                    }
                } label: {
                    Label("Short Sleep (1.5h)", systemImage: "moon.circle")
                }
            }
            
            Section("Examples") {
                Button {
                    Task {
                        await viewModel.scheduleAlertOnlyExample()
                    }
                } label: {
                    Label("Alert Only", systemImage: "bell.circle.fill")
                }
                
                Button {
                    Task {
                        await viewModel.scheduleCountdownAlertExample()
                    }
                } label: {
                    Label("With Countdown", systemImage: "timer")
                }
                
                Button {
                    Task {
                        await viewModel.scheduleCustomButtonAlertExample()
                    }
                } label: {
                    Label("Custom Button", systemImage: "alarm")
                }
            }
            
            Section("Scheduled") {
                Button {
                    Task {
                        await viewModel.scheduleMorningAlarm()
                    }
                } label: {
                    Label("Morning Alarm", systemImage: "sunrise")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
        }
    }
    
    @ViewBuilder var content: some View {
        if viewModel.hasUpcomingAlarms {
            TabView(selection: $selectedTab) {
                allAlarmsView
                    .tabItem {
                        Label("All", systemImage: "list.bullet")
                    }
                    .tag(0)
                
                if !viewModel.runningTraditionalAlarms.isEmpty {
                    traditionAlarmsView
                        .tabItem {
                            Label("Alarms", systemImage: "alarm")
                        }
                        .tag(1)
                }
                
                if !viewModel.runningTimers.isEmpty {
                    timersView
                        .tabItem {
                            Label("Timers", systemImage: "timer")
                        }
                        .tag(2)
                }
                
                if !viewModel.runningCustomAlarms.isEmpty {
                    customAlarmsView
                        .tabItem {
                            Label("Custom", systemImage: "gear")
                        }
                        .tag(3)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        } else {
            emptyStateView
        }
    }
    
    var allAlarmsView: some View {
        AlarmListView(
            alarms: viewModel.runningAlarms,
            title: "All Alarms",
            emptyMessage: "No active alarms"
        )
        .environment(viewModel)
    }
    
    var traditionAlarmsView: some View {
        AlarmListView(
            alarms: viewModel.runningTraditionalAlarms,
            title: "Scheduled Alarms",
            emptyMessage: "No scheduled alarms"
        )
        .environment(viewModel)
    }
    
    var timersView: some View {
        AlarmListView(
            alarms: viewModel.runningTimers,
            title: "Active Timers",
            emptyMessage: "No active timers"
        )
        .environment(viewModel)
    }
    
    var customAlarmsView: some View {
        AlarmListView(
            alarms: viewModel.runningCustomAlarms,
            title: "Custom Alarms",
            emptyMessage: "No custom alarms"
        )
        .environment(viewModel)
    }
    
    var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Alarms", systemImage: "alarm.waves.left.and.right")
        } description: {
            Text("Create your first alarm or timer using the quick actions or + button")
        } actions: {
            VStack(spacing: 12) {
                Button {
                    showAddSheet.toggle()
                } label: {
                    Text("Create Alarm")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                HStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.scheduleQuickNap()
                        }
                    } label: {
                        Text("Quick Nap")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        Task {
                            await viewModel.schedulePowerNap()
                        }
                    } label: {
                        Text("Power Nap")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Alarm List View
struct AlarmListView: View {
    let alarms: [ItsukiAlarm]
    let title: String
    let emptyMessage: String
    
    @Environment(AlarmKitViewModel.self) private var viewModel
    
    var body: some View {
        Group {
            if alarms.isEmpty {
                ContentUnavailableView(emptyMessage, systemImage: "alarm.slash")
            } else {
                List {
                    ForEach(alarms, id: \.id) { alarm in
                        AlarmCell(alarm: alarm)
                            .environment(viewModel)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            Task {
                                await viewModel.deleteAlarm(alarms[index])
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Alarm Cell
struct AlarmCell: View {
    let alarm: ItsukiAlarm
    @Environment(AlarmKitViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Time/Duration Display
                timeDisplay
                
                Spacer()
                
                // State Tag
                stateTag
            }
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(alarm.displayTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !alarm.displaySubtitle.isEmpty {
                    Text(alarm.displaySubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Controls for active alarms
            if alarm.state == .countdown || alarm.state == .paused {
                controlButtons
            }
            
            // Schedule info for scheduled alarms
            if alarm.isScheduled, let scheduledTime = alarm.scheduledTime {
                scheduleInfo(scheduledTime)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    var timeDisplay: some View {
        VStack(alignment: .leading) {
            if let scheduledTime = alarm.scheduledTime {
                Text(scheduledTime, style: .time)
                    .font(.title2)
                    .fontWeight(.medium)
            } else if let duration = alarm.timerDuration {
                Text(duration.formattedDuration())
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            if let icon = alarm.metadata.sleepContext?.icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var stateTag: some View {
        Text(alarm.stateLabel)
            .textCase(.uppercase)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stateColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    var stateColor: Color {
        switch alarm.state {
        case .scheduled: .blue
        case .countdown: .green
        case .paused: .yellow
        case .alerting: .red
        @unknown default: .gray
        }
    }
    
    var controlButtons: some View {
        HStack(spacing: 12) {
            if alarm.state == .countdown {
                Button {
                    Task {
                        await viewModel.pauseAlarm(alarm)
                    }
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if alarm.state == .paused {
                Button {
                    Task {
                        await viewModel.resumeAlarm(alarm)
                    }
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Button {
                Task {
                    await viewModel.stopAlarm(alarm)
                }
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            if alarm.timerDuration != nil {
                Button {
                    Task {
                        await viewModel.repeatAlarm(alarm)
                    }
                } label: {
                    Label("Repeat", systemImage: "repeat")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    func scheduleInfo(_ time: Date) -> some View {
        HStack {
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let weekdays = alarm.scheduledWeekdays, !weekdays.isEmpty {
                Text(weekdays.map(\.localizedAbbreviation).joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Once")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Extensions
extension TimeInterval {
    func formattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self % 3600) / 60
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
import AlarmKit
import SwiftUI

struct AlarmKitEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmKitViewModel.self) private var viewModel
    
    let alarm: ItsukiAlarm
    @State private var selectedTime: Date
    @State private var isUpdating = false
    
    init(alarm: ItsukiAlarm) {
        self.alarm = alarm
        self._selectedTime = State(initialValue: Self.extractAlarmTime(from: alarm))
    }
    
    // Static method to properly extract alarm time with robust fallback
    private static func extractAlarmTime(from alarm: ItsukiAlarm) -> Date {
        // First, try to extract from schedule
        if let schedule = alarm.alarm.schedule {
            switch schedule {
            case .relative(let relative):
                // Create a date for today with the alarm's time
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = relative.time.hour
                components.minute = relative.time.minute
                components.second = 0
                
                if let alarmDate = calendar.date(from: components) {
                    return alarmDate
                }
                
            case .fixed(let date):
                // For fixed alarms, use the fixed date but adjust to today
                let calendar = Calendar.current
                let alarmComponents = calendar.dateComponents([.hour, .minute], from: date)
                var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
                todayComponents.hour = alarmComponents.hour
                todayComponents.minute = alarmComponents.minute
                todayComponents.second = 0
                
                if let alarmDate = calendar.date(from: todayComponents) {
                    return alarmDate
                }
                
            @unknown default:
                break
            }
        }
        
        // Enhanced fallback: try to use the alarm's fire date if available
        if let fireDate = alarm.fireDate {
            // Extract just the time components and apply to today
            let calendar = Calendar.current
            let fireComponents = calendar.dateComponents([.hour, .minute], from: fireDate)
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            todayComponents.hour = fireComponents.hour ?? 9  // default to 9 AM
            todayComponents.minute = fireComponents.minute ?? 0
            todayComponents.second = 0
            
            if let alarmDate = calendar.date(from: todayComponents) {
                return alarmDate
            }
        }
        
        // Final fallback: use current time (should rarely happen)
        return Date()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Alarm Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 40)
                
                DatePicker("Alarm Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: deleteAlarm) {
                    Text("Delete Alarm")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: updateAlarm) {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .disabled(isUpdating)
                }
            }
        }
    }
    
    func updateAlarm() {
        isUpdating = true
        
        Task {
            // Create a form that preserves all existing alarm properties
            // but only updates the time
            var updatedForm = AlarmKitForm.fromExistingAlarm(alarm)
            updatedForm.selectedDate = selectedTime
            updatedForm.scheduleEnabled = true
            
            await viewModel.editAlarm(alarm, with: updatedForm)
            
            await MainActor.run {
                isUpdating = false
                dismiss()
            }
        }
    }
    
    func deleteAlarm() {
        Task {
            await viewModel.deleteAlarm(alarm)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// Preview removed due to AlarmKit API limitations
// Use simulator or device to test this view
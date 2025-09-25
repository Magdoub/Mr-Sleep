import AlarmKit
import SwiftUI

struct AlarmKitAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmKitViewModel.self) private var viewModel
    
    @State private var selectedTime = Date()
    @State private var isScheduling = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set Alarm Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 40)
                
                DatePicker("Alarm Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("New Alarm")
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
                    Button(action: scheduleAlarm) {
                        if isScheduling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .disabled(isScheduling)
                }
            }
        }
    }
    
    func scheduleAlarm() {
        isScheduling = true
        
        Task {
            // Create simple alarm form with just the selected time
            var simpleForm = AlarmKitForm()
            simpleForm.selectedDate = selectedTime
            simpleForm.scheduleEnabled = true
            
            await viewModel.scheduleAlarm(with: simpleForm)
            
            await MainActor.run {
                isScheduling = false
                dismiss()
            }
        }
    }
}

#Preview {
    AlarmKitAddView()
        .environment(AlarmKitViewModel())
}
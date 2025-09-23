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
                
                Button(action: scheduleAlarm) {
                    HStack {
                        if isScheduling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save Alarm")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isScheduling)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
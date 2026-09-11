import SwiftUI

struct PetPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petPreferences: PetPreferencesStore
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    
    let columns = [GridItem(.adaptive(minimum: 100, maximum: 120))]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.kristi(size: 48))
                .foregroundColor(Color(hex: "#2A2A2A"))
                .padding(.top, 24)
            
            ScrollView {
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Timer Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#2A2A2A"))
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Pomodoro (Focus)")
                                Spacer()
                                TextField("", value: $pomodoroVM.workMinutes, format: .number)
                                    .frame(width: 40)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                Stepper("", value: $pomodoroVM.workMinutes, in: 1...60)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("Short Break")
                                Spacer()
                                TextField("", value: $pomodoroVM.breakMinutes, format: .number)
                                    .frame(width: 40)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                Stepper("", value: $pomodoroVM.breakMinutes, in: 1...30)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("Long Break")
                                Spacer()
                                TextField("", value: $pomodoroVM.longBreakMinutes, format: .number)
                                    .frame(width: 40)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                Stepper("", value: $pomodoroVM.longBreakMinutes, in: 1...60)
                                    .labelsHidden()
                            }
                        }
                        .foregroundColor(Color(hex: "#2A2A2A"))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Choose Your Pet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#2A2A2A"))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(PetVariant.catalog) { variant in
                                VStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        
                                        if petPreferences.selectedVariantID == variant.id {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue, lineWidth: 3)
                                        }
                                        
                                        PetCanvasView(variant: variant, frameIndex: 0, facingRight: true, isSleeping: false)
                                            .frame(width: 60, height: 60)
                                    }
                                    .frame(width: 100, height: 100)
                                    .onTapGesture {
                                        petPreferences.selectedVariantID = variant.id
                                    }
                                    
                                    Text(variant.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#2A2A2A"))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 24)
        }
        .frame(width: 400, height: 500)
        .background(Color(hex: "#F9F6EE"))
        .environment(\.colorScheme, .light)
    }
}

import SwiftUI

struct WagerCheckInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var goalsVM: GoalsViewModel
    
    @State private var selectedGoalId: UUID?
    @State private var score: Double = 8
    @State private var outOf: Double = 10
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Weekly Check-In 📝")
                .font(.kristi(size: 48))
                .foregroundColor(Color(hex: "#2A2A2A"))
            
            Text("Enter your quiz/test score to update your long-term goal progress based on this week's effort!")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            if goalsVM.longTermGoals.isEmpty {
                Text("No long-term goals found. Add one first!")
                    .foregroundColor(.red)
            } else {
                Picker("Select Goal", selection: $selectedGoalId) {
                    Text("Select a goal").tag(UUID?(nil))
                    ForEach(goalsVM.longTermGoals, id: \.id) { goal in
                        Text(goal.title).tag(UUID?(goal.id))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 250)
                
                HStack {
                    VStack {
                        Text("Score")
                        TextField("Score", value: $score, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                    }
                    Text("/")
                        .font(.title)
                        .padding(.top, 16)
                    VStack {
                        Text("Out Of")
                        TextField("Max", value: $outOf, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                    }
                }
                
                Button(action: submitScore) {
                    Text("SUBMIT SCORE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(selectedGoalId == nil ? Color.gray : Color.blue)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                }
                .buttonStyle(.plain)
                .disabled(selectedGoalId == nil || outOf <= 0)
            }
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
            .padding(.top, 8)
        }
        .frame(width: 450, height: 400)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFED99"), Color(hex: "#FFD1DC")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(radius: 12)
        .onAppear {
            if let first = goalsVM.longTermGoals.first {
                selectedGoalId = first.id
            }
        }
    }
    
    private func submitScore() {
        guard let goalId = selectedGoalId,
              let goal = goalsVM.longTermGoals.first(where: { $0.id == goalId }) else { return }
        
        let percentage = score / outOf
        
        // Calculate one week's worth of progress
        // let oneWeek: TimeInterval = 7 * 24 * 3600
        // let totalDuration = goal.deadline?.timeIntervalSince(goal.createdAt) ?? oneWeek // default to 1 week if no deadline
        // let weekFraction = min(1.0, oneWeek / max(totalDuration, oneWeek)) // Ensure non-zero and clamped
        
        // let earnedProgress = weekFraction * percentage
        
        // goal.progressPercentage = min(1.0, goal.progressPercentage + earnedProgress)
        // if goal.progressPercentage >= 1.0 {
        //     goal.isCompleted = true
        // }
        
        NotificationCenter.default.post(name: Notification.Name("wagerCompleted"), object: nil)
        dismiss()
    }
}

import SwiftUI
import SwiftData

struct GoalsPanelView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @State private var newGoalTitle: String = ""
    @State private var goalDeadline: Date = Date().addingTimeInterval(30*24*60*60) // default 1 month
    @State private var showingWagerSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("MY GOALS")
                    .font(.kristi(size: 48))
                    .foregroundColor(Color(hex: "#2A2A2A"))
                    .padding(.top, 24)
                Spacer()
                
                Button(action: { showingWagerSheet = true }) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.red)
                        .font(.title)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 24)
                .padding(.top, 24)
            }
            .padding(.bottom, 8)
            
            // Input Area for Long Term Goals
            HStack {
                TextField("Add a new long-term goal...", text: $newGoalTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.dawning(size: 18))
                
                DatePicker("", selection: $goalDeadline, displayedComponents: .date)
                    .labelsHidden()
                    .scaleEffect(0.8)
                    .frame(width: 80)
                
                Button(action: {
                    if !newGoalTitle.isEmpty {
                        _ = goalsVM.addLongTermGoal(title: newGoalTitle, deadline: goalDeadline)
                        newGoalTitle = ""
                        goalDeadline = Date().addingTimeInterval(30*24*60*60)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 16)
            
            // Goals List
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !goalsVM.longTermGoals.isEmpty {
                        ForEach(goalsVM.longTermGoals) { goal in
                            GoalRowView(goal: goal)
                        }
                    } else {
                        Text("No goals set yet.")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#FAFAFA"))
        .sheet(isPresented: $showingWagerSheet) {
            WagerCheckInView()
        }
    }
}

struct GoalRowView: View {
    @Bindable var goal: LongTermGoal
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    
    @State private var newHabitString: String = ""
    @State private var newMilestoneString: String = ""
    @State private var msStartDate: Date = Date()
    @State private var msEndDate: Date = Date().addingTimeInterval(7*24*60*60)
    
    @State private var selectedMilestone: Milestone?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        if let index = goalsVM.longTermGoals.firstIndex(of: goal) {
                            let palette: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal]
                            Circle()
                                .fill(palette[index % palette.count])
                                .frame(width: 12, height: 12)
                        }
                        Text(goal.title)
                            .font(.dawning(size: 26))
                            .foregroundColor(.black)
                    }
                    
                    if let deadline = goal.deadline {
                        Text("Deadline: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: { goalsVM.deleteGoal(goal) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            
            // Daily Habits
            if !goal.dailyHabits.isEmpty {
                Text("Daily Habits")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#8B4513"))
                
                ForEach(goal.dailyHabits) { habit in
                    Text("• \(habit.title) (Days: \(habit.daysCompleted))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                TextField("Add daily habit...", text: $newHabitString)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                Button(action: {
                    if !newHabitString.isEmpty {
                        goalsVM.addDailyHabit(to: goal, title: newHabitString)
                        newHabitString = ""
                        taskVM.fetchTasks()
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            // Milestones
            if !goal.milestones.isEmpty {
                Text("Milestones")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#8B4513"))
                    .padding(.top, 4)
                
                ForEach(goal.milestones.sorted { $0.startDate < $1.startDate }) { ms in
                    HStack {
                        let df = DateFormatter()
                        let _ = df.dateFormat = "MM.dd.yy"
                        Text("• \(ms.title) (\(df.string(from: ms.startDate)) - \(df.string(from: ms.endDate)))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                        if let score = ms.quizScore {
                            Text("Score: \(Int(score * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Button(action: {
                                selectedMilestone = ms
                            }) {
                                Text("Pending Quiz")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Add milestone...", text: $newMilestoneString)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .frame(width: 100)
                
                DatePicker("", selection: $msStartDate, displayedComponents: .date)
                    .labelsHidden()
                    .scaleEffect(0.7)
                    .frame(width: 70)
                
                Text("-")
                
                DatePicker("", selection: $msEndDate, displayedComponents: .date)
                    .labelsHidden()
                    .scaleEffect(0.7)
                    .frame(width: 70)
                
                Button(action: {
                    if !newMilestoneString.isEmpty {
                        goalsVM.addMilestone(to: goal, title: newMilestoneString, startDate: msStartDate, endDate: msEndDate)
                        newMilestoneString = ""
                        taskVM.fetchTasks()
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.black.opacity(0.03))
        .cornerRadius(8)
        .sheet(item: $selectedMilestone) { ms in
            QuizEntryView(milestone: ms)
        }
    }
}
struct QuizEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var goalsVM: GoalsViewModel
    @Bindable var milestone: Milestone
    
    @State private var scoreString: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Complete Milestone")
                .font(.headline)
            
            Text("Enter your score for '\(milestone.title)' (0 - 100):")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            
            TextField("Score %", text: $scoreString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
                
                Button("Submit") {
                    if let score = Double(scoreString) {
                        let finalScore = max(0.0, min(1.0, score / 100.0))
                        goalsVM.updateQuizScore(for: milestone, score: finalScore)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

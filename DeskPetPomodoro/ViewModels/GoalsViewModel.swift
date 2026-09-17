import Foundation
import SwiftData
import SwiftUI

class GoalsViewModel: ObservableObject {
    var modelContext: ModelContext?
    
    @Published var longTermGoals: [LongTermGoal] = []
    
    func loadGoals() {
        guard let ctx = modelContext else { return }
        
        let descriptor = FetchDescriptor<LongTermGoal>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        if let goals = try? ctx.fetch(descriptor) {
            longTermGoals = goals
        }
    }
    
    func addLongTermGoal(title: String, deadline: Date? = nil) -> LongTermGoal {
        guard let ctx = modelContext else { fatalError("No context") }
        let newGoal = LongTermGoal(title: title, deadline: deadline)
        ctx.insert(newGoal)
        try? ctx.save()
        loadGoals()
        return newGoal
    }
    
    func addMilestone(to goal: LongTermGoal, title: String, startDate: Date, endDate: Date) {
        let milestone = Milestone(title: title, startDate: startDate, endDate: endDate)
        milestone.parentGoal = goal
        goal.milestones.append(milestone)
        try? modelContext?.save()
        loadGoals()
    }
    
    func addDailyHabit(to goal: LongTermGoal, title: String) {
        let habit = DailyHabit(title: title)
        habit.parentGoal = goal
        goal.dailyHabits.append(habit)
        try? modelContext?.save()
        loadGoals()
    }
    
    func updateQuizScore(for milestone: Milestone, score: Double) {
        milestone.quizScore = score
        try? modelContext?.save()
        loadGoals()
    }
    
    func updateMilestone(_ milestone: Milestone, startDate: Date, endDate: Date, score: Double?) {
        milestone.startDate = startDate
        milestone.endDate = endDate
        milestone.quizScore = score
        try? modelContext?.save()
        loadGoals()
    }
    
    func deleteGoal(_ goal: LongTermGoal) {
        modelContext?.delete(goal)
        try? modelContext?.save()
        loadGoals()
    }
}

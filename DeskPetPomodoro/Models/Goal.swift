import Foundation
import SwiftData

@Model
final class LongTermGoal: Identifiable {
    var id: UUID
    var title: String
    var createdAt: Date
    var deadline: Date?
    
    @Relationship(deleteRule: .cascade)
    var milestones: [Milestone] = []
    
    @Relationship(deleteRule: .cascade)
    var dailyHabits: [DailyHabit] = []
    
    // Progress calculation
    var progressPercentage: Double {
        let totalItems = milestones.count + dailyHabits.count
        if totalItems == 0 { return 0.0 }
        
        let milestoneProgress = milestones.reduce(0.0) { $0 + $1.progressContribution }
        let habitProgress = dailyHabits.reduce(0.0) { $0 + $1.progressContribution }
        
        return (milestoneProgress + habitProgress) / Double(totalItems)
    }
    
    var expectedProgressPercentage: Double {
        let totalItems = milestones.count + dailyHabits.count
        if totalItems == 0 { return 0.0 }
        
        let milestoneExpected = milestones.reduce(0.0) { $0 + $1.expectedProgress }
        let habitExpected = dailyHabits.reduce(0.0) { $0 + $1.expectedProgress }
        
        return (milestoneExpected + habitExpected) / Double(totalItems)
    }
    
    init(title: String, deadline: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.deadline = deadline
    }
}

@Model
final class Milestone: Identifiable {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var quizScore: Double? // 0.0 to 1.0. If nil, not taken yet.
    
    var daysCompleted: Int = 0
    
    var parentGoal: LongTermGoal?
    
    var progressContribution: Double {
        if let score = quizScore {
            return score
        }
        // If they haven't taken the quiz, progress is based on daily completion
        let totalDays = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 7)
        return max(0.0, min(1.0, Double(daysCompleted) / Double(totalDays)))
    }
    
    var expectedProgress: Double {
        let now = Date()
        if now < startDate { return 0.0 }
        if now >= endDate { return 1.0 }
        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = now.timeIntervalSince(startDate)
        return max(0.0, min(1.0, elapsed / totalDuration))
    }
    
    init(title: String, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.quizScore = nil
    }
}

@Model
final class DailyHabit: Identifiable {
    var id: UUID
    var title: String
    var createdAt: Date
    
    // We can track days completed by querying TodoTasks linked to this habit.
    var daysCompleted: Int = 0
    var expectedDays: Int = 30 // Example baseline, or we can make it dynamic based on goal deadline
    
    var parentGoal: LongTermGoal?
    
    var progressContribution: Double {
        if expectedDays == 0 { return 1.0 }
        return max(0.0, min(1.0, Double(daysCompleted) / Double(expectedDays)))
    }
    
    var expectedProgress: Double {
        let now = Date()
        let totalDuration = TimeInterval(expectedDays * 24 * 60 * 60)
        let elapsed = now.timeIntervalSince(createdAt)
        return max(0.0, min(1.0, elapsed / totalDuration))
    }
    
    init(title: String, expectedDays: Int = 30) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.expectedDays = expectedDays
    }
}

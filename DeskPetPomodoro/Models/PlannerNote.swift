import Foundation
import SwiftData

@Model
final class PlannerNote {
    /// Calendar-day key, e.g. "2026-09-05"
    var dayKey: String
    var content: String
    var updatedAt: Date

    init(dayKey: String, content: String = "") {
        self.dayKey = dayKey
        self.content = content
        self.updatedAt = Date()
    }
}

@Model
final class DailyPlannerData: Identifiable {
    var id: UUID
    var dateString: String // "YYYY-MM-DD" format for fast querying
    
    // Time schedule: "06:00" -> Task
    var schedule: [String: String] = [:]
    
    // Priority of the day (Checkboxes)
    var priority1: String = ""
    var priority1Done: Bool = false
    var priority2: String = ""
    var priority2Done: Bool = false
    var priority3: String = ""
    var priority3Done: Bool = false
    var priority4: String = ""
    var priority4Done: Bool = false
    var priority5: String = ""
    var priority5Done: Bool = false
    
    var waterIntake: Int = 0 // 0 to 8
    
    var appointments: String = ""
    
    var lunchPlan: String = ""
    var dinnerPlan: String = ""
    
    var gratitude: String = ""
    var toStart: Bool = false
    var ok: Bool = false
    var delay: Bool = false
    var stuck: Bool = false
    var cancel: Bool = false
    
    init(dateString: String) {
        self.id = UUID()
        self.dateString = dateString
    }
}

@Model
final class WeeklyPlannerData: Identifiable {
    var id: UUID
    var weekIdentifier: String // e.g. "YYYY-WXX"
    
    var mondayNotes: String = ""
    var tuesdayNotes: String = ""
    var wednesdayNotes: String = ""
    var thursdayNotes: String = ""
    var fridayNotes: String = ""
    var saturdayNotes: String = ""
    var sundayNotes: String = ""
    
    var weekGoals: String = ""
    
    var priority1: String = ""
    var priority1Done: Bool = false
    var priority2: String = ""
    var priority2Done: Bool = false
    var priority3: String = ""
    var priority3Done: Bool = false
    var priority4: String = ""
    var priority4Done: Bool = false
    var priority5: String = ""
    var priority5Done: Bool = false
    
    var notes: String = ""
    
    init(weekIdentifier: String) {
        self.id = UUID()
        self.weekIdentifier = weekIdentifier
    }
}

@Model
final class MonthlyPlannerData: Identifiable {
    var id: UUID
    var monthIdentifier: String // e.g. "YYYY-MM"
    
    // Dictionary mapping day number (1-31) to note string
    var dayNotes: [Int: String] = [:]
    
    var notes: String = ""
    
    init(monthIdentifier: String) {
        self.id = UUID()
        self.monthIdentifier = monthIdentifier
    }
}

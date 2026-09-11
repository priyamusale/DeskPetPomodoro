import Foundation
import SwiftData

class PlannerViewModel: ObservableObject {
    var modelContext: ModelContext? {
        didSet { 
            loadDailyData()
            loadWeeklyData()
            loadMonthlyData()
        }
    }
    
    // Dates for navigation
    @Published var selectedDate: Date = Date() {
        didSet { loadDailyData() }
    }
    @Published var selectedWeekDate: Date = Date() {
        didSet { loadWeeklyData() }
    }
    @Published var selectedMonthDate: Date = Date() {
        didSet { loadMonthlyData() }
    }
    
    // Data objects
    @Published var dailyData: DailyPlannerData?
    @Published var weeklyData: WeeklyPlannerData?
    @Published var monthlyData: MonthlyPlannerData?
    
    private var saveWorkItem: DispatchWorkItem?

    // Date Formatters
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    private let calendar = Calendar.current
    
    private var weekIdentifier: String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedWeekDate)
        return "\(components.yearForWeekOfYear ?? 0)-W\(components.weekOfYear ?? 0)"
    }
    
    private var monthIdentifier: String {
        let components = calendar.dateComponents([.year, .month], from: selectedMonthDate)
        return "\(components.year ?? 0)-\(String(format: "%02d", components.month ?? 0))"
    }
    
    // Display strings
    var dailyHeaderString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f.string(from: selectedDate)
    }
    
    var weeklyHeaderString: String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedWeekDate)
        guard let weekStart = calendar.date(from: components) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "Week of \(f.string(from: weekStart)) - \(f.string(from: weekEnd))"
    }
    
    var monthlyHeaderString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedMonthDate)
    }
    
    // MARK: Load logic
    
    private func loadDailyData() {
        guard let ctx = modelContext else { return }
        let key = dayFormatter.string(from: selectedDate)
        let descriptor = FetchDescriptor<DailyPlannerData>(predicate: #Predicate { $0.dateString == key })
        
        if let data = try? ctx.fetch(descriptor).first {
            dailyData = data
        } else {
            let data = DailyPlannerData(dateString: key)
            ctx.insert(data)
            try? ctx.save()
            dailyData = data
        }
    }
    
    private func loadWeeklyData() {
        guard let ctx = modelContext else { return }
        let key = weekIdentifier
        let descriptor = FetchDescriptor<WeeklyPlannerData>(predicate: #Predicate { $0.weekIdentifier == key })
        
        if let data = try? ctx.fetch(descriptor).first {
            weeklyData = data
        } else {
            let data = WeeklyPlannerData(weekIdentifier: key)
            ctx.insert(data)
            try? ctx.save()
            weeklyData = data
        }
    }
    
    private func loadMonthlyData() {
        guard let ctx = modelContext else { return }
        let key = monthIdentifier
        let descriptor = FetchDescriptor<MonthlyPlannerData>(predicate: #Predicate { $0.monthIdentifier == key })
        
        if let data = try? ctx.fetch(descriptor).first {
            monthlyData = data
        } else {
            let data = MonthlyPlannerData(monthIdentifier: key)
            ctx.insert(data)
            try? ctx.save()
            monthlyData = data
        }
    }
    
    // MARK: Auto Save
    func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in 
            try? self?.modelContext?.save()
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }
    
    // MARK: Navigation
    func nextDay() { selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }
    func prevDay() { selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }
    
    func nextWeek() { selectedWeekDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeekDate) ?? selectedWeekDate }
    func prevWeek() { selectedWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeekDate) ?? selectedWeekDate }
    
    func nextMonth() { selectedMonthDate = calendar.date(byAdding: .month, value: 1, to: selectedMonthDate) ?? selectedMonthDate }
    func prevMonth() { selectedMonthDate = calendar.date(byAdding: .month, value: -1, to: selectedMonthDate) ?? selectedMonthDate }
}

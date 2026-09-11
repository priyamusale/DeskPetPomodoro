import SwiftUI

struct DailyPlannerView: View {
    @EnvironmentObject var plannerVM: PlannerViewModel
    
    // Binding helper
    private var data: Binding<DailyPlannerData> {
        Binding(
            get: { plannerVM.dailyData ?? DailyPlannerData(dateString: "") },
            set: { plannerVM.dailyData = $0; plannerVM.scheduleSave() }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { plannerVM.prevDay() }) { Image(systemName: "chevron.left") }
                Spacer()
                Text("DAILY PLANNER")
                    .font(.kristi(size: 48))
                Spacer()
                Button(action: { plannerVM.nextDay() }) { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            HStack {
                Text("DATE: \(plannerVM.dailyHeaderString)")
                    .font(.dawning(size: 20))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider().padding(.horizontal, 24)
            
            // Content
            HStack(alignment: .top, spacing: 24) {
                // Left Column: Schedule
                VStack(alignment: .leading, spacing: 12) {
                    Text("TODAY'S SCHEDULE")
                        .font(.dawning(size: 18))
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(6..<24) { hour in
                                let timeStr = String(format: "%02d:00", hour)
                                HStack {
                                    Text(timeStr)
                                        .font(.dawning(size: 14))
                                        .frame(width: 40, alignment: .leading)
                                    TextField("", text: Binding(
                                        get: { data.wrappedValue.schedule[timeStr] ?? "" },
                                        set: { data.wrappedValue.schedule[timeStr] = $0; plannerVM.scheduleSave() }
                                    ))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.dawning(size: 16))
                                    .padding(.bottom, 2)
                                    .overlay(Rectangle().frame(height: 1).padding(.top, 14), alignment: .bottom)
                                    .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Right Column
                VStack(alignment: .leading, spacing: 20) {
                    // Priorities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRIORITY OF THE DAY")
                            .font(.dawning(size: 18))
                        
                        PriorityRow(text: data.priority1, isDone: data.priority1Done, vm: plannerVM)
                        PriorityRow(text: data.priority2, isDone: data.priority2Done, vm: plannerVM)
                        PriorityRow(text: data.priority3, isDone: data.priority3Done, vm: plannerVM)
                        PriorityRow(text: data.priority4, isDone: data.priority4Done, vm: plannerVM)
                        PriorityRow(text: data.priority5, isDone: data.priority5Done, vm: plannerVM)
                    }
                    
                    // Water
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WATER INTAKE")
                            .font(.dawning(size: 18))
                        HStack(spacing: 4) {
                            ForEach(1...8, id: \.self) { drop in
                                Image(systemName: drop <= data.wrappedValue.waterIntake ? "drop.fill" : "drop")
                                    .foregroundColor(Color.cyan)
                                    .onTapGesture {
                                        data.wrappedValue.waterIntake = drop
                                        plannerVM.scheduleSave()
                                    }
                            }
                        }
                    }
                    
                    // Appointments
                    VStack(alignment: .leading, spacing: 8) {
                        Text("APPOINTMENTS")
                            .font(.dawning(size: 18))
                        TextField("", text: data.appointments)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.dawning(size: 16))
                            .overlay(Rectangle().frame(height: 1).padding(.top, 14), alignment: .bottom)
                            .foregroundColor(.gray)
                    }
                    
                    // Meals
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LUNCH PLAN")
                            .font(.dawning(size: 18))
                        TextField("", text: data.lunchPlan)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.dawning(size: 16))
                            .overlay(Rectangle().frame(height: 1).padding(.top, 14), alignment: .bottom)
                            .foregroundColor(.gray)
                        
                        Text("DINNER PLAN")
                            .font(.dawning(size: 18))
                            .padding(.top, 4)
                        TextField("", text: data.dinnerPlan)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.dawning(size: 16))
                            .overlay(Rectangle().frame(height: 1).padding(.top, 14), alignment: .bottom)
                            .foregroundColor(.gray)
                    }
                    
                    // Gratitude
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TODAY, I'M GRATEFUL FOR")
                            .font(.dawning(size: 18))
                        TextField("", text: data.gratitude)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.dawning(size: 16))
                            .overlay(Rectangle().frame(height: 1).padding(.top, 14), alignment: .bottom)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#FAFAFA"))
    }
}

struct PriorityRow: View {
    @Binding var text: String
    @Binding var isDone: Bool
    let vm: PlannerViewModel
    
    var body: some View {
        HStack {
            Image(systemName: isDone ? "circle.fill" : "circle")
                .foregroundColor(.gray)
                .font(.system(size: 12))
                .onTapGesture {
                    isDone.toggle()
                    vm.scheduleSave()
                }
            TextField("", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.dawning(size: 16))
                .overlay(Rectangle().frame(height: 1).padding(.top, 14).foregroundColor(.gray.opacity(0.3)), alignment: .bottom)
        }
    }
}

struct WeeklyPlannerView: View {
    @EnvironmentObject var plannerVM: PlannerViewModel
    @EnvironmentObject var goalsVM: GoalsViewModel
    
    private var data: Binding<WeeklyPlannerData> {
        Binding(
            get: { plannerVM.weeklyData ?? WeeklyPlannerData(weekIdentifier: "") },
            set: { plannerVM.weeklyData = $0; plannerVM.scheduleSave() }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { plannerVM.prevWeek() }) { Image(systemName: "chevron.left") }
                Spacer()
                Text("WEEKLY PLANNER")
                    .font(.kristi(size: 48))
                Spacer()
                Button(action: { plannerVM.nextWeek() }) { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            HStack {
                Text("WEEK OF: \(plannerVM.weeklyHeaderString)")
                    .font(.dawning(size: 20))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider().padding(.horizontal, 24)
            
            HStack(alignment: .top, spacing: 24) {
                // Left Column: Days of the week
                VStack(alignment: .leading, spacing: 16) {
                    DayBlock(day: "MON", text: data.mondayNotes, vm: plannerVM)
                    DayBlock(day: "TUE", text: data.tuesdayNotes, vm: plannerVM)
                    DayBlock(day: "WED", text: data.wednesdayNotes, vm: plannerVM)
                    DayBlock(day: "THU", text: data.thursdayNotes, vm: plannerVM)
                    DayBlock(day: "FRI", text: data.fridayNotes, vm: plannerVM)
                    DayBlock(day: "SAT", text: data.saturdayNotes, vm: plannerVM)
                    DayBlock(day: "SUN", text: data.sundayNotes, vm: plannerVM)
                }
                .frame(maxWidth: .infinity)
                
                // Right Column
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WEEK GOALS")
                            .font(.dawning(size: 18))
                        
                        // Active Milestones for this week
                        let activeMilestones = goalsVM.longTermGoals.flatMap { $0.milestones }.filter { milestone in
                            milestone.startDate <= plannerVM.selectedWeekDate.addingTimeInterval(7*24*60*60) && milestone.endDate >= plannerVM.selectedWeekDate
                        }
                        
                        if !activeMilestones.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(activeMilestones) { ms in
                                    HStack(spacing: 4) {
                                        if let goal = ms.parentGoal, let index = goalsVM.longTermGoals.firstIndex(of: goal) {
                                            let palette: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal]
                                            Circle()
                                                .fill(palette[index % palette.count])
                                                .frame(width: 8, height: 8)
                                        } else {
                                            Text("•")
                                                .font(.dawning(size: 14))
                                        }
                                        Text(ms.title)
                                            .font(.dawning(size: 14))
                                            .foregroundColor(Color(hex: "#4A4A4A"))
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        TextEditor(text: data.weekGoals)
                            .font(.dawning(size: 16))
                            .frame(height: max(40, 80 - CGFloat(activeMilestones.count * 16)))
                            .padding(4)
                            .background(Color(hex: "#F5EFE6")) // light tan background
                            .cornerRadius(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRIORITY OF THE WEEK")
                            .font(.dawning(size: 18))
                        PriorityRow(text: data.priority1, isDone: data.priority1Done, vm: plannerVM)
                        PriorityRow(text: data.priority2, isDone: data.priority2Done, vm: plannerVM)
                        PriorityRow(text: data.priority3, isDone: data.priority3Done, vm: plannerVM)
                        PriorityRow(text: data.priority4, isDone: data.priority4Done, vm: plannerVM)
                        PriorityRow(text: data.priority5, isDone: data.priority5Done, vm: plannerVM)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.dawning(size: 18))
                        TextEditor(text: data.notes)
                            .font(.dawning(size: 16))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#FAFAFA"))
    }
}

struct DayBlock: View {
    let day: String
    @Binding var text: String
    let vm: PlannerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day)
                .font(.dawning(size: 16))
            TextField("", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.dawning(size: 16))
                .padding(.bottom, 2)
                .overlay(Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3)), alignment: .bottom)
        }
    }
}

struct MonthlyPlannerView: View {
    @EnvironmentObject var plannerVM: PlannerViewModel
    @EnvironmentObject var goalsVM: GoalsViewModel
    
    private var data: Binding<MonthlyPlannerData> {
        Binding(
            get: { plannerVM.monthlyData ?? MonthlyPlannerData(monthIdentifier: "") },
            set: { plannerVM.monthlyData = $0; plannerVM.scheduleSave() }
        )
    }
    
    // Calendar math helpers
    private var daysInMonth: Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: plannerVM.selectedMonthDate) else { return 30 }
        return range.count
    }
    
    private var firstWeekday: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: plannerVM.selectedMonthDate)
        guard let firstDate = calendar.date(from: components) else { return 1 }
        return calendar.component(.weekday, from: firstDate) // 1 = Sunday, 2 = Monday, etc.
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { plannerVM.prevMonth() }) { Image(systemName: "chevron.left") }
                Spacer()
                Text("MONTHLY PLANNER")
                    .font(.kristi(size: 48))
                Spacer()
                Button(action: { plannerVM.nextMonth() }) { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            HStack {
                Text("MONTH: \(plannerVM.monthlyHeaderString.uppercased())")
                    .font(.dawning(size: 20))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider().padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                // Days of week header
                HStack(spacing: 0) {
                    ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                        Text(day)
                            .font(.dawning(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#F5EFE6"))
                            .border(Color.gray.opacity(0.3), width: 0.5)
                    }
                }
                
                // Calendar Grid
                let totalSlots = 42 // 6 rows * 7 days
                let offset = firstWeekday - 1 // Sunday = 0 offset
                
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { col in
                                let slot = row * 7 + col
                                let dayNumber = slot - offset + 1
                                
                                MonthlyCalendarCell(
                                    dayNumber: dayNumber,
                                    daysInMonth: daysInMonth,
                                    plannerVM: plannerVM,
                                    goalsVM: goalsVM,
                                    data: data
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(24)
            
            // Notes section at bottom
            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES")
                    .font(.dawning(size: 18))
                TextEditor(text: data.notes)
                    .font(.dawning(size: 16))
                    .frame(height: 60)
                    .padding(4)
                    .background(Color.white)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#FAFAFA"))
    }
}

struct MonthlyCalendarCell: View {
    let dayNumber: Int
    let daysInMonth: Int
    @ObservedObject var plannerVM: PlannerViewModel
    @ObservedObject var goalsVM: GoalsViewModel
    @Binding var data: MonthlyPlannerData
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .border(Color.gray.opacity(0.3), width: 0.5)
            
            if dayNumber > 0 && dayNumber <= daysInMonth {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(dayNumber)")
                        .font(.dawning(size: 14))
                        .padding(.leading, 4)
                        .padding(.top, 4)
                    
                    let goalColors = activeGoalColors
                    if !goalColors.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(0..<goalColors.count, id: \.self) { i in
                                Circle()
                                    .fill(goalColors[i])
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                    }
                    
                    TextEditor(text: Binding(
                        get: { data.dayNotes[dayNumber] ?? "" },
                        set: { data.dayNotes[dayNumber] = $0; plannerVM.scheduleSave() }
                    ))
                    .font(.dawning(size: 14))
                    .padding(.horizontal, 2)
                }
            }
        }
    }
    
    private var cellDate: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: plannerVM.selectedMonthDate)
        var dayComponents = components
        dayComponents.day = dayNumber
        return Calendar.current.date(from: dayComponents) ?? Date()
    }
    
    private var activeGoalColors: [Color] {
        let date = cellDate
        var colors: [Color] = []
        let palette: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal]
        
        for (index, goal) in goalsVM.longTermGoals.enumerated() {
            let color = palette[index % palette.count]
            
            // Check if this goal has any active milestones today
            let hasActiveMilestone = goal.milestones.contains { ms in
                ms.startDate <= date && ms.endDate >= date
            }
            // Check if this goal has any daily habits
            let hasDailyHabits = !goal.dailyHabits.isEmpty
            
            if hasActiveMilestone || hasDailyHabits {
                colors.append(color)
            }
        }
        return colors
    }
}

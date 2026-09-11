import SwiftUI
import SwiftData

@main
struct DeskPetPomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var pomodoroVM = PomodoroViewModel()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var plannerVM = PlannerViewModel()
    @StateObject private var petVM = PetViewModel()
    @StateObject private var petPreferences = PetPreferencesStore()
    @StateObject private var goalsVM = GoalsViewModel()
    @StateObject private var coworkingVM = CoworkingViewModel()
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([TodoTask.self, PlannerNote.self, LongTermGoal.self, Milestone.self, DailyHabit.self, DailyPlannerData.self, WeeklyPlannerData.self, MonthlyPlannerData.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Migration failed, wiping old database: \(error)")
            // Wipe the database
            let fileManager = FileManager.default
            if let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let appDirectory = supportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier ?? "DeskPetPomodoro")
                let defaultStore = supportDirectory.appendingPathComponent("default.store")
                let defaultStoreShm = supportDirectory.appendingPathComponent("default.store-shm")
                let defaultStoreWal = supportDirectory.appendingPathComponent("default.store-wal")
                do {
                    try? fileManager.removeItem(at: appDirectory)
                    try? fileManager.removeItem(at: defaultStore)
                    try? fileManager.removeItem(at: defaultStoreShm)
                    try? fileManager.removeItem(at: defaultStoreWal)
                }
            }
            
            // Second try
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after wipe: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            MainWindowView()
                .environmentObject(pomodoroVM)
                .environmentObject(taskVM)
                .environmentObject(plannerVM)
                .environmentObject(petVM)
                .environmentObject(petPreferences)
                .environmentObject(goalsVM)
                .environmentObject(coworkingVM)
                .modelContainer(modelContainer)
                .onAppear {
                    taskVM.modelContext = modelContainer.mainContext
                    plannerVM.modelContext = modelContainer.mainContext
                    goalsVM.modelContext = modelContainer.mainContext
                    goalsVM.loadGoals()
                    appDelegate.petVM = petVM
                    appDelegate.petPreferences = petPreferences
                    appDelegate.coworkingVM = coworkingVM
                    appDelegate.showOverlay(pomodoroVM: pomodoroVM)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 640)
        
        Window("Pomodoro Timer", id: "PomodoroWindow") {
            TimerPanelView()
                .environmentObject(pomodoroVM)
                .environmentObject(goalsVM)
                .environmentObject(petVM)
                .environment(\.colorScheme, .light)
                .frame(minWidth: 320, minHeight: 380)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

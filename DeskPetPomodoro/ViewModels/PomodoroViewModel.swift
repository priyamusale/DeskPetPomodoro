import Foundation
import AppKit
import Combine

// MARK: - Notification Names

extension Notification.Name {
    static let pomodoroSessionStarted = Notification.Name("pomodoroSessionStarted")
    static let pomodoroSessionPaused  = Notification.Name("pomodoroSessionPaused")
    static let pomodoroSessionEnded   = Notification.Name("pomodoroSessionEnded")
    static let taskCompleted          = Notification.Name("taskCompleted")
}

// MARK: - PomodoroViewModel

class PomodoroViewModel: ObservableObject {

    // Timer state
    @Published var phase: PomodoroPhase = .idle
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var isRunning: Bool = false
    @Published var completedPomodoros: Int = 0

    // User-configurable durations (minutes)
    @Published var workMinutes: Int {
        didSet {
            UserDefaults.standard.set(workMinutes, forKey: "workMinutes")
            if phase == .idle || phase == .work { timeRemaining = Double(workMinutes) * 60 }
        }
    }
    @Published var breakMinutes: Int {
        didSet {
            UserDefaults.standard.set(breakMinutes, forKey: "breakMinutes")
            if phase == .shortBreak { timeRemaining = Double(breakMinutes) * 60 }
        }
    }
    @Published var longBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakMinutes, forKey: "longBreakMinutes")
            if phase == .longBreak { timeRemaining = Double(longBreakMinutes) * 60 }
        }
    }

    private var timer: Timer?

    // Derived helpers
    var workDuration: TimeInterval  { Double(workMinutes)  * 60 }
    var breakDuration: TimeInterval { Double(breakMinutes) * 60 }
    var longBreakDuration: TimeInterval { Double(longBreakMinutes) * 60 }

    var progress: Double {
        let total: TimeInterval
        switch phase {
        case .shortBreak: total = breakDuration
        case .longBreak: total = longBreakDuration
        default: total = workDuration
        }
        guard total > 0 else { return 0 }
        return 1.0 - (timeRemaining / total)
    }

    var timeString: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var phaseLabel: String {
        switch phase {
        case .idle, .work: return "Pomodoro"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }

    init() {
        let wm = UserDefaults.standard.integer(forKey: "workMinutes")
        workMinutes  = wm  > 0 ? wm  : 25
        let bm = UserDefaults.standard.integer(forKey: "breakMinutes")
        breakMinutes = bm  > 0 ? bm  : 5
        let lm = UserDefaults.standard.integer(forKey: "longBreakMinutes")
        longBreakMinutes = lm > 0 ? lm : 10
        timeRemaining = Double(workMinutes) * 60
    }

    // MARK: Controls
    
    func setPhase(_ newPhase: PomodoroPhase) {
        pauseSession()
        phase = newPhase
        switch newPhase {
        case .shortBreak:
            timeRemaining = breakDuration
        case .longBreak:
            timeRemaining = longBreakDuration
        default:
            timeRemaining = workDuration
        }
    }

    func startSession() {
        if phase == .idle {
            phase = .work
            timeRemaining = workDuration
        }
        isRunning = true
        scheduleTimer()
        NotificationCenter.default.post(name: .pomodoroSessionStarted, object: nil)
    }

    func pauseSession() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.post(name: .pomodoroSessionPaused, object: nil)
    }

    func resetSession() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        switch phase {
        case .shortBreak:
            timeRemaining = breakDuration
        case .longBreak:
            timeRemaining = longBreakDuration
        default:
            timeRemaining = workDuration
        }
        NotificationCenter.default.post(name: .pomodoroSessionPaused, object: nil)
    }

    // MARK: Private

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
    }

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 1 {
            timeRemaining -= 1
        } else {
            timeRemaining = 0
            sessionCompleted()
        }
    }

    private func sessionCompleted() {
        timer?.invalidate()
        timer = nil

        if phase == .work || phase == .idle {
            completedPomodoros += 1
        }

        // Gentle non-jarring sound
        NSSound(named: NSSound.Name("Purr"))?.play()

        NotificationCenter.default.post(name: .pomodoroSessionEnded, object: nil)

        // Transition
        if phase == .work || phase == .idle {
            if completedPomodoros % 4 == 0 {
                setPhase(.longBreak)
            } else {
                setPhase(.shortBreak)
            }
            startSession()
        } else {
            setPhase(.work)
            NotificationCenter.default.post(name: .pomodoroSessionPaused, object: nil)
        }
    }
}

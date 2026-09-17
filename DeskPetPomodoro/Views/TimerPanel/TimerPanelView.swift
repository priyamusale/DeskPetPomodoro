import SwiftUI

struct TimerPanelView: View {
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var showingTimerMenu = false
    @State private var showCoworkingPanel = false
    @ObservedObject var distractionMonitor = DistractionMonitor.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Top Pills
            HStack(spacing: 12) {
                PhasePill(title: "Pomodoro", isActive: pomodoroVM.phase == .work || pomodoroVM.phase == .idle) {
                    pomodoroVM.setPhase(.work)
                }
                PhasePill(title: "Short Break", isActive: pomodoroVM.phase == .shortBreak) {
                    pomodoroVM.setPhase(.shortBreak)
                }
                PhasePill(title: "Long Break", isActive: pomodoroVM.phase == .longBreak) {
                    pomodoroVM.setPhase(.longBreak)
                }
            }
            .padding(.top, 24)
            // Timer Text
            Text(pomodoroVM.timeString)
                .font(.dawning(size: 84))
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Start/Pause Button
            Button(action: {
                if pomodoroVM.isRunning {
                    pomodoroVM.pauseSession()
                } else {
                    pomodoroVM.startSession()
                }
            }) {
                Text(pomodoroVM.isRunning ? "PAUSE" : "START")
                    .font(.kristi(size: 36))
                    .foregroundColor(Color(hex: "#4A4A4A"))
                    .frame(width: 140, height: 44)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 16)
            // Bottom Controls
            HStack(spacing: 20) {
                Spacer()
                
                CircularIconButton(icon: "heart.fill") {
                    showCoworkingPanel = true
                }
                .foregroundColor(.red)
                .popover(isPresented: $showCoworkingPanel) {
                    CoworkingPanelView()
                        .frame(width: 300, height: 350)
                }
                
                CircularIconButton(icon: distractionMonitor.isEnabled ? "eye.fill" : "eye.slash") {
                    distractionMonitor.isEnabled.toggle()
                }
                .foregroundColor(distractionMonitor.isEnabled ? .blue : Color(hex: "#4A4A4A"))
                
                CircularIconButton(icon: "arrow.counterclockwise") {
                    pomodoroVM.resetSession()
                }
                
                CircularIconButton(icon: "gearshape.fill") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowSettings"), object: nil)
                }
                
                CircularIconButton(icon: "house.fill") {
                    openWindow(id: "MainWindow")
                }
                
                CircularIconButton(icon: "arrow.up.left.and.arrow.down.right") {
                    openWindow(id: "PomodoroWindow")
                }
                
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFE4E1"), Color(hex: "#FFD1DC")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 2, y: 4)
    }
}

struct PhasePill: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#4A4A4A"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? Color.white : Color.white.opacity(0.4))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CircularIconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#4A4A4A"))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

import Cocoa
import SwiftUI
import Combine

class PetOverlayWindowController: NSWindowController {
    private var cancellables = Set<AnyCancellable>()
    private let pomodoroVM: PomodoroViewModel
    
    // Track if we're in a walk-to-close animation
    private var isWalkingToClose = false
    private var homeX: CGFloat = 0
    
    init(petVM: PetViewModel, preferences: PetPreferencesStore, pomodoroVM: PomodoroViewModel, coworkingVM: CoworkingViewModel) {
        self.pomodoroVM = pomodoroVM
        let screen = NSScreen.main ?? NSScreen.screens[0]
        
        let startX = screen.frame.minX - 34
        self.homeX = startX
        
        // Make the window 280px wide so speech bubble doesn't clip
        let rect = NSRect(x: startX,
                          y: screen.frame.minY,
                          width: 280,
                          height: 200)
        
        let window = NSWindow(contentRect: rect,
                              styleMask: .borderless,
                              backing: .buffered,
                              defer: false)
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let rootView = PetOverlayView()
            .environmentObject(petVM)
            .environmentObject(preferences)
            .environmentObject(pomodoroVM)
            .environmentObject(coworkingVM)
        
        window.contentView = NSHostingView(rootView: rootView)
        
        super.init(window: window)
        
        // Observe Pomodoro progress to slide the pet across the screen
        pomodoroVM.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateWindowPosition()
            }
            .store(in: &cancellables)
        
        // Listen for the punishment event to trigger the walk-to-close animation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWalkToClose),
            name: NSNotification.Name("walkToCloseTab"),
            object: nil
        )
    }
    
    private func updateWindowPosition() {
        guard !isWalkingToClose else { return }
        guard let window = self.window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let progress = pomodoroVM.progress
        let minX: CGFloat = screen.frame.minX - 34
        let maxX: CGFloat = screen.frame.maxX - 140 + 34
        
        homeX = minX + (maxX - minX) * CGFloat(progress)
        
        var newFrame = window.frame
        newFrame.origin.x = homeX
        window.setFrame(newFrame, display: true, animate: false)
    }
    
    @objc private func onWalkToClose() {
        guard let window = self.window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        guard !isWalkingToClose else { return }
        
        isWalkingToClose = true
        let savedHomeX = homeX
        
        // Chrome's tab bar is near the top of the screen. 
        // We walk to the x-position of the active Chrome window's tab bar area.
        // Approximate target: center-top of the screen (where the tab is likely to be)
        let targetX = screen.frame.midX - 70
        let targetY = screen.frame.maxY - 80 // near the top (tab bar area)
        
        // Step 1: Walk to the tab (animate over 1.5 seconds)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(
                NSRect(x: targetX, y: targetY, width: window.frame.width, height: window.frame.height),
                display: true
            )
        }) {
            // Step 2: Close the tab once we arrive
            NotificationCenter.default.post(name: NSNotification.Name("executePunishment"), object: nil)
            
            // Step 3: Walk back home after a short pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, let window = self.window else { return }
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 1.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    let homeY = screen.frame.minY
                    window.animator().setFrame(
                        NSRect(x: savedHomeX, y: homeY, width: window.frame.width, height: window.frame.height),
                        display: true
                    )
                }) {
                    self.isWalkingToClose = false
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


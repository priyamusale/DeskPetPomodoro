import Cocoa
import SwiftUI
import Combine

class PetOverlayWindowController: NSWindowController {
    private var cancellables = Set<AnyCancellable>()
    private let pomodoroVM: PomodoroViewModel
    
    init(petVM: PetViewModel, preferences: PetPreferencesStore, pomodoroVM: PomodoroViewModel, coworkingVM: CoworkingViewModel) {
        self.pomodoroVM = pomodoroVM
        let screen = NSScreen.main ?? NSScreen.screens[0]
        
        let rect = NSRect(x: screen.frame.minX - 34,
                          y: screen.frame.minY,
                          width: 140,
                          height: 140)
        
        let window = NSWindow(contentRect: rect,
                              styleMask: .borderless,
                              backing: .buffered,
                              defer: false)
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating // Above normal windows
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let rootView = PetOverlayView()
            .environmentObject(petVM)
            .environmentObject(preferences)
            .environmentObject(pomodoroVM)
            .environmentObject(coworkingVM)
        
        window.contentView = NSHostingView(rootView: rootView)
        
        super.init(window: window)
        
        // Observe progress to move window
        pomodoroVM.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateWindowPosition()
            }
            .store(in: &cancellables)
    }
    
    private func updateWindowPosition() {
        guard let window = self.window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let progress = pomodoroVM.progress
        let minX: CGFloat = screen.frame.minX - 34
        // Account for window width, allow visual pet to hit right edge
        let maxX: CGFloat = screen.frame.maxX - window.frame.width + 34
        
        let currentX = minX + (maxX - minX) * CGFloat(progress)
        
        var newFrame = window.frame
        newFrame.origin.x = currentX
        window.setFrame(newFrame, display: true, animate: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

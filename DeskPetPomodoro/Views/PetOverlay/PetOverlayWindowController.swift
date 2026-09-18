import Cocoa
import SwiftUI
import Combine

class PetOverlayWindowController: NSWindowController {
    private var cancellables = Set<AnyCancellable>()
    private let pomodoroVM: PomodoroViewModel
    private let petVM: PetViewModel
    
    private var isWalkingToClose = false
    private var homeX: CGFloat = 0
    private var homeY: CGFloat = 0
    private var walkTimer: Timer?
    
    init(petVM: PetViewModel, preferences: PetPreferencesStore, pomodoroVM: PomodoroViewModel, coworkingVM: CoworkingViewModel) {
        self.pomodoroVM = pomodoroVM
        self.petVM = petVM
        let screen = NSScreen.main ?? NSScreen.screens[0]
        
        let startX = screen.frame.minX - 34
        let startY = screen.frame.minY
        self.homeX = startX
        self.homeY = startY
        
        let rect = NSRect(x: startX, y: startY, width: 280, height: 200)
        
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
        
        pomodoroVM.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateWindowPosition() }
            .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(onWalkToClose),
            name: NSNotification.Name("walkToCloseTab"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(onSnapToLeftEdge),
            name: NSNotification.Name("snapToLeftEdge"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(onCancelWalkAndGoHome),
            name: NSNotification.Name("cancelWalkAndGoHome"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(onWalkBackHome),
            name: NSNotification.Name("walkBackHome"), object: nil
        )
    }
    
    private func updateWindowPosition() {
        // Don't move while walking or while distracted
        guard !isWalkingToClose else { return }
        guard DistractionMonitor.shared.consecutiveDistractedSeconds == 0 else { return }
        guard let window = self.window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let progress = pomodoroVM.progress
        let minX: CGFloat = screen.frame.minX - 34
        let maxX: CGFloat = screen.frame.maxX - 140 + 34
        
        homeX = minX + (maxX - minX) * CGFloat(progress)
        homeY = screen.frame.minY
        
        var newFrame = window.frame
        newFrame.origin.x = homeX
        newFrame.origin.y = homeY
        window.setFrame(newFrame, display: true, animate: false)
    }
    
    @objc private func onSnapToLeftEdge() {
        guard let window = self.window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        guard !isWalkingToClose else { return }
        // Snap smoothly to left edge
        let leftEdgeX = screen.frame.minX - 34
        homeX = leftEdgeX
        homeY = screen.frame.minY
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(
                NSRect(x: leftEdgeX, y: homeY, width: window.frame.width, height: window.frame.height),
                display: true
            )
        }
    }
    
    @objc private func onWalkToClose() {
        guard let window = self.window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        guard !isWalkingToClose else { return }
        
        walkTimer?.invalidate()
        isWalkingToClose = true
        
        let screenMidX = screen.frame.midX
        let petIsOnLeft = (homeX + 70) < screenMidX
        
        // Target: near Chrome's tab bar at top of screen
        let tabBarY = screen.frame.maxY - 40
        let tabBarX: CGFloat = screen.frame.midX - 350
        
        let startX = homeX
        let startY = homeY
        
        let totalDuration: TimeInterval = 300 // 5 minutes
        let timeUp: TimeInterval = 200        // 3m 20s walking up
        let timeAcross: TimeInterval = 100    // 1m 40s walking horizontally
        
        let startTime = Date()
        
        // Initial rotation
        DispatchQueue.main.async {
            self.petVM.facingRight = petIsOnLeft
            self.petVM.walkRotation = petIsOnLeft ? -90 : 90
            self.petVM.startWalking()
        }
        
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] t in
            guard let self = self, let win = self.window else { t.invalidate(); return }
            let elapsed = Date().timeIntervalSince(startTime)
            
            if elapsed >= totalDuration {
                t.invalidate()
                win.setFrameOrigin(NSPoint(x: tabBarX, y: tabBarY))
                // DistractionMonitor will handle closing the tab when its timer reaches 15 mins.
                // We just stop the creep.
                return
            }
            
            if elapsed < timeUp {
                let p = elapsed / timeUp
                let currentY = startY + (tabBarY - startY) * CGFloat(p)
                win.setFrameOrigin(NSPoint(x: startX, y: currentY))
            } else {
                if self.petVM.walkRotation != 0 {
                    self.petVM.walkRotation = 0
                    self.petVM.facingRight = tabBarX > startX
                }
                
                let p = (elapsed - timeUp) / timeAcross
                let currentX = startX + (tabBarX - startX) * CGFloat(p)
                win.setFrameOrigin(NSPoint(x: currentX, y: tabBarY))
            }
        }
    }
    
    @objc private func onCancelWalkAndGoHome() {
        guard isWalkingToClose else { return }
        walkTimer?.invalidate()
        animateHomeQuickly(duration: 1.5)
    }
    
    @objc private func onWalkBackHome() {
        walkTimer?.invalidate()
        animateHomeQuickly(duration: 3.0)
    }
    
    private func animateHomeQuickly(duration: TimeInterval) {
        guard let window = self.window else { return }
        
        // If we are currently rotated, reset rotation immediately for the walk back
        DispatchQueue.main.async {
            self.petVM.walkRotation = 0
            self.petVM.facingRight = self.homeX > window.frame.origin.x
        }
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrameOrigin(NSPoint(x: homeX, y: homeY))
        }) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isWalkingToClose = false
                self.petVM.walkRotation = 0
                self.petVM.facingRight = true
                if !self.pomodoroVM.isRunning {
                    self.petVM.stopWalking()
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



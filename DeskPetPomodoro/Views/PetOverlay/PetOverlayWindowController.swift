import Cocoa
import SwiftUI
import Combine

class UnconstrainedWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect // Do not clamp to screen bounds
    }
}

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
        
        let window = UnconstrainedWindow(contentRect: rect,
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
            self.petVM.facingRight = !petIsOnLeft
            self.petVM.walkRotation = petIsOnLeft ? 90 : 270
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
        animateHomeQuickly(duration: 60.0)
    }
    
    @objc private func onWalkBackHome() {
        walkTimer?.invalidate()
        animateHomeQuickly(duration: 60.0)
    }
    
    private func animateHomeQuickly(duration: TimeInterval) {
        guard let window = self.window else { return }
        
        walkTimer?.invalidate()
        let startX = window.frame.origin.x
        let startY = window.frame.origin.y
        let endX = self.homeX
        let endY = self.homeY
        
        let distX = abs(startX - endX)
        let distY = abs(startY - endY)
        let totalDist = distX + distY
        
        guard totalDist > 0 else {
            self.finishWalkBack()
            return
        }
        
        let timeAcross = duration * TimeInterval(distX / totalDist)
        let timeDown = duration * TimeInterval(distY / totalDist)
        
        let startTime = Date()
        let petIsOnLeft = (homeX + 70) < (NSScreen.main?.frame.midX ?? 0)
        
        DispatchQueue.main.async {
            if distX > 0 {
                // Moving horizontally back
                self.petVM.walkRotation = 0
                self.petVM.facingRight = endX > startX
            } else {
                // Moving down only
                self.petVM.facingRight = petIsOnLeft
                self.petVM.walkRotation = petIsOnLeft ? 90 : 270
            }
        }
        
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] t in
            guard let self = self, let win = self.window else { t.invalidate(); return }
            let elapsed = Date().timeIntervalSince(startTime)
            
            if elapsed >= duration {
                t.invalidate()
                win.setFrameOrigin(NSPoint(x: endX, y: endY))
                self.finishWalkBack()
                return
            }
            
            if elapsed < timeAcross {
                // Moving ACROSS
                let p = elapsed / timeAcross
                let currentX = startX + (endX - startX) * CGFloat(p)
                win.setFrameOrigin(NSPoint(x: currentX, y: startY))
            } else {
                // Transitioning to DOWN
                if distX > 0 && (elapsed - timeAcross) < (1.0/60.0 * 2) {
                    DispatchQueue.main.async {
                        self.petVM.facingRight = petIsOnLeft
                        self.petVM.walkRotation = petIsOnLeft ? 90 : 270
                    }
                }
                
                let p = (elapsed - timeAcross) / timeDown
                let currentY = startY + (endY - startY) * CGFloat(p)
                win.setFrameOrigin(NSPoint(x: endX, y: currentY))
            }
        }
    }
    
    private func finishWalkBack() {
        DispatchQueue.main.async {
            self.isWalkingToClose = false
            self.petVM.walkRotation = 0
            self.petVM.facingRight = true
            if !self.pomodoroVM.isRunning {
                self.petVM.stopWalking()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



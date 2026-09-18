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
    }
    
    private func updateWindowPosition() {
        guard !isWalkingToClose else { return }
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
    
    @objc private func onWalkToClose() {
        guard let window = self.window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        guard !isWalkingToClose else { return }
        
        isWalkingToClose = true
        let savedHomeX = homeX
        let savedHomeY = homeY
        
        let screenMidX = screen.frame.midX
        let petIsOnLeft = (homeX + 70) < screenMidX
        
        // Target: near Chrome's tab bar at top of screen
        let tabBarY = screen.frame.maxY - 200
        let tabBarX: CGFloat = screen.frame.midX - 200
        
        // STEP 1: Rotate sprite -90° (head up = walking up), walk straight UP (~45s)
        DispatchQueue.main.async {
            self.petVM.facingRight = petIsOnLeft
            self.petVM.walkRotation = petIsOnLeft ? -90 : 90  // -90 = head up facing left-screen, 90 = head up facing right-screen
        }
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 45
            ctx.timingFunction = CAMediaTimingFunction(name: .linear)
            window.animator().setFrame(
                NSRect(x: homeX, y: tabBarY, width: window.frame.width, height: window.frame.height),
                display: true
            )
        }) { [weak self] in
            guard let self = self else { return }
            
            // STEP 2: Rotate back to 0°, walk HORIZONTALLY to tab (~20s)
            let movingRight = tabBarX > self.homeX
            DispatchQueue.main.async {
                self.petVM.walkRotation = 0
                self.petVM.facingRight = movingRight
            }
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 20
                ctx.timingFunction = CAMediaTimingFunction(name: .linear)
                window.animator().setFrame(
                    NSRect(x: tabBarX, y: tabBarY, width: window.frame.width, height: window.frame.height),
                    display: true
                )
            }) { [weak self] in
                guard let self = self else { return }
                
                // STEP 3: Close the tab
                NotificationCenter.default.post(name: NSNotification.Name("executePunishment"), object: nil)
                
                // STEP 4: Walk back home — horizontal first (~20s), then down (~45s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let goingBack = savedHomeX > tabBarX
                    DispatchQueue.main.async {
                        self.petVM.walkRotation = 0
                        self.petVM.facingRight = goingBack
                    }
                    
                    NSAnimationContext.runAnimationGroup({ ctx in
                        ctx.duration = 20
                        ctx.timingFunction = CAMediaTimingFunction(name: .linear)
                        window.animator().setFrame(
                            NSRect(x: savedHomeX, y: tabBarY, width: window.frame.width, height: window.frame.height),
                            display: true
                        )
                    }) {
                        // Walk straight DOWN
                        DispatchQueue.main.async {
                            // Rotate 90° to face downward direction
                            self.petVM.walkRotation = petIsOnLeft ? 90 : -90
                            self.petVM.facingRight = petIsOnLeft
                        }
                        NSAnimationContext.runAnimationGroup({ ctx in
                            ctx.duration = 45
                            ctx.timingFunction = CAMediaTimingFunction(name: .linear)
                            window.animator().setFrame(
                                NSRect(x: savedHomeX, y: savedHomeY, width: window.frame.width, height: window.frame.height),
                                display: true
                            )
                        }) {
                            // Reset
                            DispatchQueue.main.async {
                                self.petVM.walkRotation = 0
                                self.petVM.facingRight = true
                            }
                            self.isWalkingToClose = false
                        }
                    }
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



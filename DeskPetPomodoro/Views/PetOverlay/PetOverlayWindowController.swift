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
        
        // Determine which side of the screen the pet is on
        let screenMidX = screen.frame.midX
        let petIsOnLeft = (homeX + 70) < screenMidX   // pet center vs screen center
        
        // Chrome tab bar is ~40px from top of screen
        // If on left: walk up along left edge, then right to center of tabs
        // If on right: walk up along right edge, then left to center of tabs
        let tabBarY = screen.frame.maxY - 200          // near the tab bar
        let tabBarX: CGFloat = petIsOnLeft
            ? screen.frame.midX - 200                  // tabs are roughly center-right area
            : screen.frame.midX - 200                  // same target regardless

        // STEP 1: Face upward direction, walk STRAIGHT UP along same X edge
        DispatchQueue.main.async {
            self.petVM.facingRight = petIsOnLeft ? true : false
        }
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 1.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(
                NSRect(x: homeX, y: tabBarY, width: window.frame.width, height: window.frame.height),
                display: true
            )
        }) { [weak self] in
            guard let self = self else { return }
            
            // STEP 2: Walk HORIZONTALLY to the tab position (facing the direction of travel)
            let movingRight = tabBarX > self.homeX
            DispatchQueue.main.async {
                self.petVM.facingRight = movingRight
            }
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 1.0
                ctx.timingFunction = CAMediaTimingFunction(name: .linear)
                window.animator().setFrame(
                    NSRect(x: tabBarX, y: tabBarY, width: window.frame.width, height: window.frame.height),
                    display: true
                )
            }) { [weak self] in
                guard let self = self else { return }
                
                // STEP 3: Close the tab
                NotificationCenter.default.post(name: NSNotification.Name("executePunishment"), object: nil)
                
                // STEP 4: Walk back DOWN along the edge (straight down to home Y)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    // First go back to home X
                    let facingHomeDir = savedHomeX > tabBarX
                    DispatchQueue.main.async {
                        self.petVM.facingRight = facingHomeDir
                    }
                    
                    NSAnimationContext.runAnimationGroup({ ctx in
                        ctx.duration = 1.0
                        ctx.timingFunction = CAMediaTimingFunction(name: .linear)
                        window.animator().setFrame(
                            NSRect(x: savedHomeX, y: tabBarY, width: window.frame.width, height: window.frame.height),
                            display: true
                        )
                    }) {
                        // Then walk straight down
                        DispatchQueue.main.async {
                            self.petVM.facingRight = petIsOnLeft ? true : false
                        }
                        NSAnimationContext.runAnimationGroup({ ctx in
                            ctx.duration = 1.2
                            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                            window.animator().setFrame(
                                NSRect(x: savedHomeX, y: savedHomeY, width: window.frame.width, height: window.frame.height),
                                display: true
                            )
                        }) {
                            self.petVM.facingRight = true
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



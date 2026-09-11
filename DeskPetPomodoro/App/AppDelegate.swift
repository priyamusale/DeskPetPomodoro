import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindowController: PetOverlayWindowController?
    var petVM: PetViewModel?
    var petPreferences: PetPreferencesStore?
    var coworkingVM: CoworkingViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Overlay window is initialized on demand
        NotificationCenter.default.addObserver(forName: Notification.Name("showPomodoroTimer"), object: nil, queue: .main) { _ in
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app alive for the pet overlay
    }

    func showOverlay(pomodoroVM: PomodoroViewModel) {
        guard let petVM = petVM, let petPreferences = petPreferences, let coworkingVM = coworkingVM else { return }
        
        if overlayWindowController == nil {
            overlayWindowController = PetOverlayWindowController(petVM: petVM, preferences: petPreferences, pomodoroVM: pomodoroVM, coworkingVM: coworkingVM)
        }
        overlayWindowController?.showWindow(nil)
    }

    func hideOverlay() {
        overlayWindowController?.close()
        overlayWindowController = nil
    }
}

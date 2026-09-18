import Foundation
import Cocoa

class DistractionMonitor: ObservableObject {
    static let shared = DistractionMonitor()
    
    @Published var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    private var timer: Timer?
    @Published var consecutiveDistractedSeconds = 0
    
    private let blacklistedDomains = ["youtube.com", "instagram.com", "tiktok.com", "facebook.com"]
    
    // Configurable thresholds for testing
    // Currently set to 10 seconds for warning, 20 seconds for closing the tab.
    // Change to 10 * 60 (600) and 15 * 60 (900) for real usage.
    let warningThresholdSeconds = 10
    let punishmentThresholdSeconds = 20
    
    private var hasWarned = false
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        stopMonitoring()
        consecutiveDistractedSeconds = 0
        hasWarned = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkActiveTab()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkActiveTab() {
        let scriptSource = """
        if application "Google Chrome" is running then
            tell application "Google Chrome"
                if (count of windows) > 0 then
                    set tabURL to URL of active tab of front window
                    set winTitle to name of front window
                    return tabURL & "|" & winTitle
                else
                    return "|"
                end if
            end tell
        else
            return "|"
        end if
        """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let result = script.executeAndReturnError(&error)
            if let resultString = result.stringValue {
                handleResult(resultString)
            } else {
                if let error = error {
                    print("AppleScript Error: \(error)")
                }
                resetCounter()
            }
        } else {
            resetCounter()
        }
    }
    
    private func handleResult(_ resultString: String) {
        if resultString == "|" || resultString.isEmpty {
            resetCounter()
            return
        }
        
        let isDistracted = blacklistedDomains.contains { domain in
            resultString.lowercased().contains(domain.lowercased()) || resultString.lowercased().contains(domain.replacingOccurrences(of: ".com", with: ""))
        }
        
        print("Tough Love Check -> \(resultString) | isDistracted: \(isDistracted) | Consecutive: \(consecutiveDistractedSeconds)")
        
        if isDistracted {
            consecutiveDistractedSeconds += 5
            
            if consecutiveDistractedSeconds >= punishmentThresholdSeconds {
                print("Tough Love -> Punishing!")
                punishAndCloseTab()
            } else if consecutiveDistractedSeconds >= warningThresholdSeconds && !hasWarned {
                print("Tough Love -> Warning!")
                warnUser()
            }
        } else {
            resetCounter()
        }
    }
    
    private func resetCounter() {
        consecutiveDistractedSeconds = 0
        hasWarned = false
    }
    
    private func warnUser() {
        hasWarned = true
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("showDistractionWarning"), object: nil)
        }
    }
    
    private func punishAndCloseTab() {
        let scriptSource = """
        tell application "Google Chrome"
            close active tab of front window
        end tell
        """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&error)
        }
        
        resetCounter()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("showDistractionPunishment"), object: nil)
        }
    }
}
